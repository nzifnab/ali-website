class AddPlayerNameToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :player_name, :text
  end
end
