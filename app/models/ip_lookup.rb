# frozen_string_literal: true

# Represents a cached IP lookup
class IpLookup < ApplicationRecord
  # Extract organization name information from the RDAP results
  def name
    # We currently look in two places
    (rdap_result.dig('entities', 0, 'vcardArray', 1)&.detect { |a| a.first == 'fn' }&.last ||
     rdap_result['name'])
  end
end
