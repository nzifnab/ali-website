class CorpStock < ApplicationRecord

  def self.purchaseable
    # In case we later decide
    # not everything here should be listed
    # on the form.
    where("price_updated_at >= ? OR current_stock > ?", 8.days.ago, 0)
  end

  # Performed every couple hours via
  # heroku scheduler & the
  # update_prices:go rake task
  def self.update_from_spreadsheet!
    PurchasePriceSheet.data.each do |item_name, item_data|
      Rails.logger.info("at=corp_stock type=info desc='Recording stock/price of #{item_name}'")
      stock = CorpStock.where(item: item_name.strip).first_or_initialize
      stock.assign_attributes(
        price_updated_at: item_data["PriceLastUpdated"],
        external_sale_price: num_from_string(item_data["ExternalSalePrice"]),
        desired_stock: num_from_string(item_data["DesiredStock"]),
        current_stock: num_from_string(item_data["CurrentStock"]),
        corp_member_sale_price: num_from_string(item_data["CorpMemberSalePrice"]),
        buy_price: num_from_string(item_data["CurrentBuyPrice"]),
        item_type: item_data["Type"]
      )
      stock.save!
    end
  end

  def self.num_from_string(val)
    val.to_s.strip.gsub(",", "")
  end
end
