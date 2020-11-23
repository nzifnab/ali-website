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


    #config.google_client_id = ENV['GOOGLE_CLIENT_ID']
    #config.google_client_secret = ENV['GOOGLE_CLIENT_SECRET']
    config.google_api_key = ENV['GOOGLE_API_KEY']
  end
end
