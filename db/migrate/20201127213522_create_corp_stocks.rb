class CreateCorpStocks < ActiveRecord::Migration[6.0]
  def change
    create_table :corp_stocks do |t|
      t.text :item
      t.text :item_type
      t.datetime :price_updated_at
      t.decimal :external_sale_price, precision: 15, scale: 2
      t.bigint :desired_stock
      t.bigint :current_stock
      t.decimal :corp_member_sale_price, precision: 15, scale: 2
      t.decimal :buy_price, precision: 15, scale: 2

      t.timestamps
    end
  end
end
