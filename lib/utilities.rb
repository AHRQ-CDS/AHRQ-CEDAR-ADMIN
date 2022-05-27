# frozen_string_literal: true

# Module to store utility functions across the application
module Utilities
  def parse_date_string(date_string, error_context)
    Date.parse(date_string) unless date_string.nil?
  rescue Date::Error
    (warnings << error_context) || 'Unspecified error'
  end
end
