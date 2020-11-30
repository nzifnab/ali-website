class AddAdminTokenToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :admin_token, :text
  end
end
