class AddTokenToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :token, :text
  end
end
