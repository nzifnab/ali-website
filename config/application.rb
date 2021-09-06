require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AliWebsite
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_record.schema_format = :sql

    # GMT+0:00 to match the timestamps from
    # the spreadsheets.
    config.time_zone = "Europe/London"


    # To allow the website to authenticate against the google API
    # as a service account, make sure to set the following environment
    # variables, which can be located from the credentials
    # file downloaded from google's credentials index page:
    # GOOGLE_ACCOUNT_TYPE='service_account'
    # GOOGLE_CLIENT_EMAIL=''
    # GOOGLE_PRIVATE_KEY=''
    config.google_api_key = ENV['GOOGLE_API_KEY']
    config.ali_market_sheet_id = ENV['MARKET_SHEET_ID']
    config.discord_invite_link = ENV['DISCORD_LINK']
    config.corp_member_token = ENV['CORP_MEMBER_TOKEN']
    config.order_discord_channel = ENV["ORDER_DISCORD_CHANNEL"] || "MISSING: {ORDER_DISCORD_CHANNEL}"
  end
end
