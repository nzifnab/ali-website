class CorpStock < ApplicationRecord
  belongs_to :blueprint, class_name: "CorpStock", optional: true

  before_create :set_blueprint_id

  def self.purchaseable
    # In case we later decide
    # not everything here should be listed
    # on the form.
    where(visible: true).order(id: :asc)
  end

  def self.last_imported_on
    last_run_entry.price_updated_on
  end

  def self.last_run_entry
    # In this "magic row", `price_updated_on` is actually the last time
    # that the corp stock was updated from the spreadsheet.
    @last_run_entry ||= CorpStock.where(item: "last_run_at").first_or_create(
      sale_valid: false,
      price_updated_on: 1.year.ago,
      visible: false
    )
  end

  def material_loss?
    # Retrievers get sold at a very slight loss sometimes, and that's ok.
    purchase_price_metadata["MaterialLoss"] && item != "Retriever"
  end

  # Performed every hour via
  # heroku scheduler & the
  # update_prices:go rake task
  def self.update_from_spreadsheet!
    sheet = PurchasePriceSheet.new
    stocks_recorded_on = sheet.stock_last_updated_on
    stock_last_import_on = last_imported_on

    sheet.data.each do |item_name, item_data|
      Rails.logger.info("at=corp_stock type=info desc='Recording price of #{item_name}'")
      stock = CorpStock.where(item: item_name.strip).first_or_initialize
      attrs = {
        price_updated_on: item_data["PriceLastUpdated"],
        external_sale_price: num_from_string(item_data["ExternalSalePrice"]),
        desired_stock: num_from_string(item_data["DesiredStock"]),
        corp_member_sale_price: num_from_string(item_data["CorpMemberSalePrice"]),
        buy_price: num_from_string(item_data["CurrentBuyPrice"]),
        item_type: item_data["Type"],
        sale_valid: item_data["SaleValid"],
        purchase_price_metadata: item_data[:metadata],
        visible: item_data[:metadata]["SaleVisibleOnSite"]
      }

      if ENV['FORCE_STOCK_RELOAD'] || stock_last_import_on < stocks_recorded_on
        # _only_ update stocks from the spreadsheet if they have been manually updated
        # since the last time they were recorded.
        Rails.logger.info("at=corp_stock type=info desc='Recording stock of #{item_name}'")
        attrs = attrs.merge(
          current_stock: num_from_string(item_data["CurrentStock"])
        )
      end
      stock.assign_attributes(attrs)
      stock.save!
    end

    if stock_last_import_on < stocks_recorded_on
      last_run_entry.update_column(:price_updated_on, Date.current)
    end
  end

  def self.num_from_string(val)
    val.to_s.strip.gsub(",", "")
  end

  def ship?
    item_type =~ /^Ship\-/
  end

  def blueprint?
    item_type == "Blueprint"
  end

  def faction_bs?
    ship? && ["Rattlesnake", "Machariel", "Bhaalgorn", "Nestor", "Barghest", "Nightmare", "Vindicator"].include?(item)
  end

  def faction_bs_blueprint?
    item_type == "Blueprint" && ["Rattlesnake Blueprint", "Machariel Blueprint", "Bhaalgorn Blueprint", "Nestor Blueprint", "Barghest Blueprint", "Nightmare Blueprint", "Vindicator Blueprint"].include?(item)
  end

  def resource?
    ["Mineral", "Planetary"].include?(item_type)
  end

  def price_up_to_date?
    7.days.ago < price_updated_on
  end

  def require_blueprint_provided?
    faction_bs? && blueprint.current_stock <= 0
  end

  def blueprint_price_reduction(corp_member_flag)
    return 0 unless ship?

    bp_raw_cost = purchase_price_metadata["ShipBlueprintSellPrice"].to_f

    contract_modifier = (corp_member_flag ? 1 : SettingData[:contract_multiplier])

    return bp_raw_cost / contract_modifier
  end


  def purchaseable?(corp_member_flag)
    return false if material_loss? && !corp_member_flag
    # Always buyable if 'sale valid' flag is true
    return true if sale_valid?

    # Corp members can still buy items that are in stock if
    # 'sale valid' ISN'T allowed, BUT the item is in stock; except for ships or bps
    # because that almost certainly means the pricing or blueprint info is out
    # of date
    return true if current_stock > 0 && corp_member_flag && !(ship? || blueprint?)

    # Allow bp's & resources to be ordered by corp members regardless of stock level,
    # as long
    # as the pricing info is recent. If not in stock a RE'er can/should handle the
    # request.
    # This doesn't apply to datacores/debris, as those can be harder to gather
    # on-demand.
    return true if corp_member_flag && (blueprint? || resource?) && price_up_to_date? && !faction_bs_blueprint?


    false
  end

  # before_create
  def set_blueprint_id
    return unless ship?

    bp = CorpStock.where(item: "#{item} Blueprint").first_or_initialize(
      visible: false
    )
    self.blueprint_id = bp.id
  end
end
