# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'webmock/minitest'
WebMock.disable_net_connect!

# Set up some dummy importer configuration settings for testing
Rails.configuration.cds_connect_basic_auth_username = 'DUMMY-KEY'
Rails.configuration.cds_connect_basic_auth_password = 'DUMMY-KEY'
Rails.configuration.cds_connect_username = 'DUMMY-KEY'
Rails.configuration.cds_connect_password = 'DUMMY-KEY'
Rails.configuration.cds_connect_base_url = 'http://DUMMY-URL/'
Rails.configuration.ehc_feed_url = 'http://DUMMY-URL/product-feed'
Rails.configuration.srdr_base_url = 'http://DUMMY-URL/'
Rails.configuration.srdr_api_key = 'DUMMY-KEY'
Rails.configuration.ngc_base_url = 'http://DUMMY-URL/'

# Disable version tracking for tests
PaperTrail.enabled = false

# Except where we want it
def with_versioning
  was_enabled = PaperTrail.enabled?
  PaperTrail.enabled = true
  begin
    yield
  ensure
    PaperTrail.enabled = was_enabled
  end
end

# Force pack compilation before forking to prevent race condition; see https://github.com/rails/webpacker/issues/2860
Webpacker.manifest.lookup('missing.js')

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # We use factories instead of fixtures
  include FactoryBot::Syntax::Methods

  # Add more helper methods to be used by all tests here...
end
