# frozen_string_literal: true

# IP lookups controller that looks up names for IP address
class IpLookupsController < ApplicationController
  # Given an IP address lookup a human readable name for that IP using RDAP
  def index
    @ip = params[:ip]

    # First see if it's a valid looking IP address
    if (IPAddr.new(@ip) rescue false) # rubocop:disable Style/RescueModifier

      # Look in our DB first and if it's not there we look it up using RDAP
      ip_lookup = IpLookup.find_or_create_by(ip_address: @ip) do |lookup|
        lookup.rdap_result = RDAP.ip(@ip)
      end

      @name = ip_lookup.name

    end
  rescue StandardError
    @name = 'Lookup failed'
  end
end
