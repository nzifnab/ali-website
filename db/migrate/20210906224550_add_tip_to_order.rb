class AddTipToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :tip, :decimal, precision: 15, scale: 2

    Order.all.update_all(tip: 0)
  end
end
