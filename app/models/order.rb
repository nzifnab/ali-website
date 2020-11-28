class Order < ApplicationRecord
  has_many :line_items

  accepts_nested_attributes_for :line_items, reject_if: -> (attrs){attrs['quantity'].to_i <= 0}

  def self.order_for_form(external=true)
    order = new

    CorpStock.purchaseable.each do |stock|
      price = external ? stock.external_sale_price : stock.corp_member_sale_price
      order.line_items.build(corp_stock: stock, price: price)
    end
    order
  end
end
