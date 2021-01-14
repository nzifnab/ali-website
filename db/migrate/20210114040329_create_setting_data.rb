class CreateSettingData < ActiveRecord::Migration[6.0]
  def change
    create_table :setting_data do |t|
      t.jsonb :settings

      t.timestamps
    end
  end
end
