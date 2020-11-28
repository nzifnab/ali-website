class CreateLineItems < ActiveRecord::Migration[6.0]
  def change
    create_table :line_items do |t|
      t.references :corp_stock, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.bigint :quantity
      t.decimal :price, precision: 15, scale: 2

      t.timestamps
    end
  end
end
