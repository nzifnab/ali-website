module OrdersHelper
  def isk_currency(val, include_decimals = false)
    precision = (include_decimals ? 2 : 0)
    val ||= 0
    if val >= 100_000
      precision = 0
    end
    number_to_currency val, unit: "Ƶ", precision: precision
  end

  def order_status_badge_class(order)
    if order.pending?
      "badge-secondary"
    elsif order.complete?
      "badge-success"
    elsif order.cancelled?
      "badge-danger"
    end
  end

  def display_contract_fee
    "#{((1 - SettingData[:contract_multiplier]) * 100).round}%"
  end
end
