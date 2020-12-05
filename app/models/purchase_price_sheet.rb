class PurchasePriceSheet < GoogleSheet

  SHEET_ID = Rails.application.config.ali_market_sheet_id.freeze

  def self.data
    new.data
  end

  def initialize
    super(SHEET_ID)
  end

  def data
    # names = values_from_named_range("ItemNames").flatten
    # stock = values_from_named_range("CurrentStock").flatten
    # result = {}
    # names.each_with_index do |name, index|
    #   result[name] = stock[index]
    # end
    # result
    content = values_from_named_range("PurchaseWebsiteData")
    names = values_from_named_range("ItemNamesPublic").flatten
    metadata = spreadsheet_service.get_spreadsheet_values(
      @sheet_id,
      "PurchasePrices!A1:AM",
      date_time_render_option: :serial_number,
      value_render_option: :unformatted_value
    ).values

    labels = content[0]
    metadata_labels = metadata[0]

    result = {}
    names.each_with_index do |name, index|
      result[name] = {}

      labels.each_with_index do |label, label_index|
        result[name][label] = content[index+1][label_index]
      end

      result[name][:metadata] = {}
      metadata_labels.each_with_index do |metalabel, label_index|
        result[name][:metadata][metalabel] = metadata[index+1][label_index]
      end
    end
    result
  end

  def update_current_stock(update_list)
    raise "Deprecated update_current_stock: This app no longer pushes updates to the stock spreadsheet"
    # This is done in the scheduler task that also collects the data
    # initially... It would be a little more efficient to do this at the same
    # time you're initially looping through the rows, but also more complex to
    # write. I'm not worried about it. This'll only happen every 1-2 hours.
    names = values_from_named_range("ItemNames").flatten
    stock = values_from_named_range("ItemStock").flatten

    values = []
    names.each_with_index do |name, index|
      values << (update_list[name] || stock[index])
    end

    write_values_to_named_range("ItemStock", [values])
  end
end
