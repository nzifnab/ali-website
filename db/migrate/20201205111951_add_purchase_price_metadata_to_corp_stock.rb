class AddPurchasePriceMetadataToCorpStock < ActiveRecord::Migration[6.0]
  def change
    add_column :corp_stocks, :purchase_price_metadata, :jsonb, default: {}
    add_column :line_items, :purchase_price_metadata, :jsonb, default: {}
  end
end
