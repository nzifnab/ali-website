class PurchasePriceSheet < GoogleSheet

  SHEET_ID = Rails.application.config.ali_market_sheet_id.freeze

  def self.data
    new.data
  end

  def self.settings
    new.settings
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
      "PurchasePrices!A1:AZ",
      date_time_render_option: :formatted_string,
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

  def stock_last_updated_on
    @stock_last_updated_on ||= Date.parse spreadsheet_service.get_spreadsheet_values(
      @sheet_id,
      "InventoryImport!B1",
      date_time_render_option: :formatted_string,
      value_render_option: :unformatted_value
    ).values.flatten.first
  end

  def settings
    result = {}

    [
      :contract_multiplier,
      :alliance_profit_percent,
      :corp_profit_percent,

      :corp_member_other_profit_margin,
      :corp_member_ship_profit_margin,
      :external_other_profit_margin,
      :external_ship_profit_margin,

      :pricing_expiration_duration
    ].each do |setting_name|
      result[setting_name] = get_val(setting_name.to_s.camelize)
    end

    result
  end

    private

      def get_val(range_name)
        values_from_named_range(range_name).flatten.first
      end
end
