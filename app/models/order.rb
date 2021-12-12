class Order < ApplicationRecord
  belongs_to :setting_data, optional: true
  has_many :line_items, dependent: :destroy, inverse_of: :order
  has_secure_token
  has_secure_token :admin_token

  accepts_nested_attributes_for :line_items, reject_if: -> (attrs){attrs['quantity'].blank?}

  before_create :set_prices_from_stock

  validates :player_name, presence: {message: "Player Name is required"}
  validate :validate_not_empty

  def self.order_for_form(external=true)
    order = new

    CorpStock.purchaseable.preload(:blueprint).each do |stock|
      price = external ? stock.external_sale_price : stock.corp_member_sale_price
      order.line_items.build(corp_stock: stock, price: price)
    end
    order
  end

  def rebuild_for_form(external)
    CorpStock.purchaseable.where.not(id: line_items.map(&:corp_stock_id)).each do |stock|
      price = external ? stock.external_sale_price : stock.corp_member_sale_price
      line_items.build(corp_stock: stock, price: price)
    end
    self
  end

  def self.get(token)
    Order.preload(line_items: :corp_stock).find_by_token(token)
  end

  def self.filter(state)
    if !["complete", "cancelled", "pending"].include?(state)
      state = "pending"
    end

    where(status: state)
  end

  def settings
    @settings ||= (setting_data || SettingData.order(created_at: :asc).first).settings
  end

  def complete!
    line_items.each do |line_item|
      stock = line_item.corp_stock
      new_stock = [0, stock.current_stock - line_item.quantity].max
      stock.update!(current_stock: new_stock)
    end
    update_column(:status, "complete")
  end

  def cancel!
    update_column(:status, "cancelled")
  end

  def pending?
    status == "pending"
  end

  def complete?
    status == "complete"
  end

  def cancelled?
    status == "cancelled"
  end

  # Should be in a decorator but I'm too lazy to install draper and deal w/
  # decorator classes, so i'll do it here ;p
  def display_status
    status
  end

  def total
    subtotal + contract_fee + tip.to_f
  end

  def total_without_contract_fee
    # I should probably fix this; external orders
    # dont' record contract fee separately, but
    # AL orders do :P
    contract? ? subtotal : (total * SettingData[:contract_multiplier])
  end

  def tip_after_contract_fee
    tip * SettingData[:contract_multiplier]
  end

  def corp_member?
    corp_member_type != "external"
  end

  def contract?
    # For AL Members
    corp_member_type == "contract"
  end

  def donation?
    corp_member_type == "donation"
  end

  def external?
    corp_member_type == "external"
  end

  def includes_in_stock_items?
    stock_status[:one_in_stock]
  end

  def includes_out_of_stock_items?
    stock_status[:one_out_of_stock]
  end

  def includes_alliance_margin?
    stock_status[:alliance_margin]
  end

  def any_blueprints_supplied_by_customer?
    stock_status[:bp_supplied]
  end

  def in_stock?
    stock_status[:all_in_stock]
  end

  def stock_status
    @stock_status ||= begin
      status_result = {
        all_in_stock: true,
        one_in_stock: false,
        one_out_of_stock: false,
        bp_supplied: false,
        alliance_margin: false
      }

      line_items.each do |li|
        if li.pending_stock?
          status_result[:all_in_stock] = false
          status_result[:one_out_of_stock] = true
        else
          status_result[:one_in_stock] = true
        end
        if li.blueprint_provided?
          status_result[:bp_supplied] = true
        end
        if li.corp_stock.ship?
          status_result[:alliance_margin] = true
        end
      end
      status_result
    end
  end

  def out_of_stock_line_items
    line_items.select(&:pending_stock?)
  end

  def tip=(val)
    write_attribute(:tip, val.to_s.gsub(/[^0-9]/, ""))
  end

  private

  # before_create
  def set_prices_from_stock
    # Makes sure to set each line item's price directly from the corp price and
    # not trust the value from the form
    tot = 0
    line_items.each do |li|
      li.price = (corp_member? ? li.corp_stock.corp_member_sale_price : li.corp_stock.external_sale_price)

      if li.corp_stock.require_blueprint_provided?
        li.blueprint_provided = true
      end

      tot += (li.price * li.quantity) - (li.blueprint_price_reduction * li.quantity)
    end
    self.subtotal = tot

    if contract?
      # Sorry I know the spreadsheet has this third value for AL vs ALI pricing, but it's frankly easier to do here
      self.contract_fee = subtotal * ((1-SettingData[:contract_multiplier]) / SettingData[:contract_multiplier])
    end
    self.tip = 0 if tip.blank?

    self.setting_data = SettingData.current
  end

  # validate
  def validate_not_empty
    if line_items.empty?
      errors.add(:base, "Cannot submit an empty order.")
    end
  end
end
