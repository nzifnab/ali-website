class AddSettingDataIdToLineItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :orders, :setting_data, foreign_key: true
  end
end
