module OrdersHelper
  def isk_currency(val, include_decimals = false)
    precision = (include_decimals ? 2 : 0)
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

  def link_to_tracker_spreadsheet
    link_to "View Manufacture Tracker Spreadsheet", "https://docs.google.com/spreadsheets/d/1lX7-5yIHRwQKzHPRY95xbK6t3f7bYJeZDMv3quLlnE0", target: "_blank"
  end
end
