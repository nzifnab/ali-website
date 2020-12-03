class AddSaleValidToCorpStock < ActiveRecord::Migration[6.0]
  def change
    add_column :corp_stocks, :sale_valid, :boolean, null: false, default: false
  end
end
