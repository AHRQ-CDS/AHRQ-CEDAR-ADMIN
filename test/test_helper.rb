# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'webmock/minitest'
WebMock.disable_net_connect!

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

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # We use factories instead of fixtures
  include FactoryBot::Syntax::Methods

  # Add more helper methods to be used by all tests here...
end
