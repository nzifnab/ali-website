class PurchasePriceSheet < GoogleSheet

  SHEET_ID = "1vsYPArvK-5Ah0mIVQIa9MnMk5EQFian6xrghUSEKF4s".freeze

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
    names = values_from_named_range("ItemNames").flatten
    labels = content[0]

    result = {}
    names.each_with_index do |name, index|
      result[name] = {}

      labels.each_with_index do |label, label_index|
        result[name][label] = content[index+1][label_index]
      end
    end
    result
  end
end
