class Order < ApplicationRecord
  has_many :line_items, dependent: :destroy, inverse_of: :order
  has_secure_token
  has_secure_token :admin_token

  accepts_nested_attributes_for :line_items, reject_if: -> (attrs){attrs['quantity'].blank?}

  before_create :set_prices_from_stock

  validates :player_name, presence: {message: "Player Name is required"}
  validate :validate_not_empty

  def self.order_for_form(external=true)
    order = new

    CorpStock.purchaseable.each do |stock|
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
    subtotal + contract_fee
  end

  def corp_member?
    corp_member_type != "external"
  end

  def contract?
    # For AL Members
    corp_member_type == "contract"
  end

  private

  # before_create
  def set_prices_from_stock
    # Makes sure to set each line item's price directly from the corp price and
    # not trust the value from the form
    tot = 0
    line_items.each do |li|
      li.price = (corp_member? ? li.corp_stock.corp_member_sale_price : li.corp_stock.external_sale_price)
      tot += (li.price * li.quantity)
    end
    self.subtotal = tot

    if contract?
      # Sorry I know the spreadsheet has this third value for AL vs ALI pricing, but it's frankly easier to do here
      self.contract_fee = subtotal * (0.08 / 0.92)
    end
  end

  # validate
  def validate_not_empty
    if line_items.empty?
      errors.add(:base, "Cannot submit an empty order.")
    end
  end
end
