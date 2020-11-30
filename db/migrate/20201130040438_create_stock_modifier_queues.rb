class CreateStockModifierQueues < ActiveRecord::Migration[6.0]
  def change
    create_table :stock_modifier_queues do |t|
      t.references :order, null: false, foreign_key: true
      t.datetime :executed_at

      t.timestamps
    end
  end
end
