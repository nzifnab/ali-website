class LineItem < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :corp_stock
  belongs_to :order

  validates :quantity, numericality: {greater_than: 0, message: ->(object, data){ "'Quantity' for #{object.corp_stock.item} must be greater than 0." }}
  validate :external_order_above_fulfillment_quantity

  def total
    price * quantity
  end

  def pending_stock?
    quantity > corp_stock.current_stock
  end

  private

  # validate
  def external_order_above_fulfillment_quantity
    # Fulfillment restriction never applies for ships, or corp members
    # Or if the 'desired stock' is 0, let the order go to negative and we'll
    # work on collecting it (IE: morphite)
    return if corp_stock.ship?
    return if order.corp_member?
    return if corp_stock.desired_stock <= 0

    # The quantity of this resource that is in current
    # pending orders
    outstanding_quantities = LineItem.joins(:order).
      where(orders: {status: "pending"}).
      where(corp_stock_id: corp_stock_id).
      sum(:quantity)

    buyable_amount = [0, (corp_stock.current_stock - outstanding_quantities) - corp_stock.desired_stock].max.to_i

    # Do not allow the purchase of resources that would bring it's quantity (when added
    # to other outstanding orders) to fall below our fulfillment % (desired_stock)
    if buyable_amount == 0 && quantity > 0
      errors.add(:quantity, "Other orders have claimed our remaining stock of #{corp_stock.item}, this item has been removed from your order. You may submit again if this is acceptable or contact us on discord.")
      self.quantity = nil
    elsif quantity > buyable_amount
      errors.add(:quantity, "You cannot order more than #{number_with_delimiter(buyable_amount)} #{corp_stock.item} due to our current levels of stock. The quantity has been adjusted automatically to this maximum amount, you may submit again if acceptable.")
      self.quantity = buyable_amount
    end
  end
end
