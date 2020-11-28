class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.decimal :total, precision: 15, scale: 2

      t.timestamps
    end
  end
end
