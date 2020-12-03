class AddCorpMemberFlagToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :corp_member, :boolean, null: false, default: false
  end
end
