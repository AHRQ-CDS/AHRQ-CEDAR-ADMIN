# frozen_string_literal: true

require 'test_helper'
require 'axe/matchers/be_axe_clean'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: {
    args: ['--headless', '--disable-gpu', '--no-sandbox', '--disable-dev-shm-usage']
  }

  include Devise::Test::IntegrationHelpers

  # https://github.com/dequelabs/axe-core-gems
  def assert_axe_accessible(page, matcher = Axe::Matchers::BeAxeClean.new.according_to(
    :wcag2a, :wcag2aa, :wcag21a, :wcag21aa
  ))
    audit_result = matcher.audit(page)
    assert(audit_result.passed?, audit_result.failure_message)
  end
end
