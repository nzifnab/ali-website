class Order < ApplicationRecord
  has_many :line_items, dependent: :destroy
  has_one :stock_modifier_queue
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
    create_stock_modifier_queue
    update(status: "complete")
  end

  def pending?
    status != "complete"
  end

  def pending_stock_update?
    status == "complete" && !stock_modifier_queue.complete?
  end

  def complete?
    status == "complete" && stock_modifier_queue.complete?
  end

  # Should be in a decorator but I'm too lazy to install draper and deal w/
  # decorator classes, so i'll do it here ;p
  def display_status
    if pending?
      status
    elsif pending_stock_update?
      "complete: stock update pending"
    elsif complete?
      "complete"
    end
  end

  private

  # before_create
  def cache_total_price
    self.total = line_items.sum{|li| li.price * li.quantity}
  end
end
