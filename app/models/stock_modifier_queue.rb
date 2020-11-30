class StockModifierQueue < ApplicationRecord
  belongs_to :order

  validates_uniqueness_of :order_id

  def self.run!
    updated_stock = {}
    preload(order: {line_items: :corp_stock}).where(executed_at: nil).each do |queue|
      queue.order.line_items.each do |line_item|
        stock = line_item.corp_stock
        stock.update!(current_stock: stock.current_stock - line_item.quantity)
        updated_stock[stock.item] = stock.current_stock
        puts "Updating #{stock.item} stock to #{stock.current_stock}"
      end
    end

    PurchasePriceSheet.new.update_current_stock(updated_stock)
    update(executed_at: Time.zone.now)
  end

  def complete?
    !!executed_at
  end
end
