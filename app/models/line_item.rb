class LineItem < ApplicationRecord
  belongs_to :corp_stock
  belongs_to :order
end
