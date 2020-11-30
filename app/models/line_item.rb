class LineItem < ApplicationRecord
  belongs_to :corp_stock
  belongs_to :order

  def total
    price * quantity
  end

  def pending_stock?
    quantity < corp_stock.current_stock
  end
end
