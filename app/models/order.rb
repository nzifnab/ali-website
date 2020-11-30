class Order < ApplicationRecord
  has_many :line_items, dependent: :destroy
  has_secure_token
  has_secure_token :admin_token

  accepts_nested_attributes_for :line_items, reject_if: -> (attrs){attrs['quantity'].to_i <= 0}

  before_create :cache_total_price

  def self.order_for_form(external=true)
    order = new

    CorpStock.purchaseable.each do |stock|
      price = external ? stock.external_sale_price : stock.corp_member_sale_price
      order.line_items.build(corp_stock: stock, price: price)
    end
    order
  end

  def self.get(token)
    Order.preload(line_items: :corp_stock).find_by_token(token)
  end

  def complete!
    line_items.each do |line_item|
      stock = line_item.corp_stock
      stock.update!(current_stock: stock.current_stock - line_item.quantity)
    end
    update(status: "complete")
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

  private

  # before_create
  def cache_total_price
    self.total = line_items.sum{|li| li.price * li.quantity}
  end
end
