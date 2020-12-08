class AddAlMemberToOrder < ActiveRecord::Migration[6.0]
  def change
    # Maybe be one of: "external", "donation" (ALI members), and "contract" (AL members)
    add_column :orders, :corp_member_type, :text, default: "external"

    Order.all.each do |order|
      if order.corp_member?
        order.update_column(:corp_member_type, "donation")
      else
        order.update_column(:corp_member_type, "external")
      end
    end

    remove_column :orders, :corp_member, :boolean
    change_column_null :orders, :corp_member_type, false

    add_column :orders, :contract_fee, :bigint, default: 0, null: false
    rename_column :orders, :total, :subtotal
  end
end
