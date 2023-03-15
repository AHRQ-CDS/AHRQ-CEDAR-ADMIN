# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class SearchLogsController < ApplicationController
  def index
    @search_logs = SearchLog.order(start_time: :desc).page params[:page]

    # Takes an optional parameter of an IP address (which we make sure is valid)
    @ip = params[:ip] if (IPAddr.new(params[:ip]) rescue false) # rubocop:disable Style/RescueModifier
    return unless @ip

    # Restrict the logs to those matching the provided IP
    @search_logs = @search_logs.where('client_ip = inet ?', @ip)
  end
end
