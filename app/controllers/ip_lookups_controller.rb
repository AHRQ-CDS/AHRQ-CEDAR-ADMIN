class IpLookupsController < ApplicationController

  # Given an IP address lookup a human readable name for that IP using RDAP
  def index
    # Make sure it's a valid looking IP address
    ip = params[:ip] if (IPAddr.new(params[:ip]) rescue false) # rubocop:disable Style/RescueModifier

    # If not valid return an empty result
    return render json: {} unless ip

    # Look in our DB first and if it's not there we look it up using RDAP
    ip_lookup = IpLookup.find_or_create_by(ip_address: ip) do |ip_lookup|
      ip_lookup.rdap_result = RDAP.ip(ip)
    end

    # See if we can find a human readable name; look in two places
    name = ip_lookup.rdap_result.dig('entities', 0, 'vcardArray', 1)&.detect { |a| a.first == 'fn' }&.last
    name ||= ip_lookup.rdap_result['name']

    # Render
    render json: { name: name }
  end

end
