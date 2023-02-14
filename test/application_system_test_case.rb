# frozen_string_literal: true

require 'test_helper'
require 'axe/matchers/be_axe_clean'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400] do |option|
    option.add_argument('headless')
    option.add_argument('disable-gpu')
    option.add_argument('no-sandbox')
    option.add_argument('disable-dev-shm-usage')
  end

  include Devise::Test::IntegrationHelpers

  # https://github.com/dequelabs/axe-core-gems
  def assert_axe_accessible(page, matcher = Axe::Matchers::BeAxeClean.new.according_to(
    :wcag2a, :wcag2aa, :wcag21a, :wcag21aa
  ))
    audit_result = matcher.audit(page)
    assert(audit_result.passed?, audit_result.failure_message)
  end
end
