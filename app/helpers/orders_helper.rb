module OrdersHelper
  def isk_currency(val, include_decimals = false)
    number_to_currency val, unit: "Ƶ", precision: (include_decimals ? 2 : 0)
  end

  def order_status_badge_class(order)
    if order.pending?
      "badge-secondary"
    elsif order.pending_stock_update?
      "badge-info"
    elsif order.complete?
      "badge-success"
    end
  end
end
