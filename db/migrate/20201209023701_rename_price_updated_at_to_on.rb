class RenamePriceUpdatedAtToOn < ActiveRecord::Migration[6.0]
  def change
    add_column :corp_stocks, :price_updated_on, :date
    remove_column :corp_stocks, :price_updated_at, :datetime
  end
end
