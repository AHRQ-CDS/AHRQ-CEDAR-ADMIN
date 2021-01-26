require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CedarAdmin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Settings for USPSTF importer
    config.uspstf_home_page = 'https://www.uspreventiveservicestaskforce.org/uspstf/'
    config.uspstf_base_url = "https://data.uspreventiveservicestaskforce.org/api/json?key=#{ENV['CEDAR_USPSTF_API_KEY']}"

    # Settings for CDS Connect importer
    config.cds_connect_home_page = 'https://cds.ahrq.gov/cdsconnect'
    config.cds_connect_basic_auth_username = ENV['CEDAR_CDS_CONNECT_BASIC_AUTH_USERNAME']
    config.cds_connect_basic_auth_password = ENV['CEDAR_CDS_CONNECT_BASIC_AUTH_PASSWORD']
    config.cds_connect_username = ENV['CEDAR_CDS_CONNECT_USERNAME']
    config.cds_connect_password = ENV['CEDAR_CDS_CONNECT_PASSWORD']
    config.cds_connect_base_url = ENV['CEDAR_CDS_CONNECT_BASE_URL']

    # Settings for the EHC importer
    config.ehc_home_page = 'https://effectivehealthcare.ahrq.gov'
    config.ehc_base_url = 'https://effectivehealthcare.ahrq.gov'
  end
end
