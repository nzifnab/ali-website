class RemoveStockModifierQueue < ActiveRecord::Migration[6.0]
  def up
    drop_table :stock_modifier_queues
  end
end
