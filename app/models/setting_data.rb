class SettingData < ApplicationRecord
  def self.record_settings!
    last_setting = order(created_at: :desc).first

    if !last_setting || Date.current > (last_setting.created_at + 1.day).to_date
      @settings = nil
      new_settings = PurchasePriceSheet.settings

      create!(settings: new_settings.stringify_keys)
    end
  end

  def self.current
    order(created_at: :desc).first
  end

  def self.settings
    @settings ||= current.settings
  end

  def settings
    @settings_symbolized ||= read_attribute(:settings).symbolize_keys
  end

  def self.[](setting_name)
    settings[setting_name.to_sym]
  end

  def self.to_h
    settings
  end
end
