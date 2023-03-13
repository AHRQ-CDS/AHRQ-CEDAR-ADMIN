# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class SearchLogsController < ApplicationController
  def index
    @search_logs = SearchLog.order(start_time: :desc).page params[:page]
    # Takes an optional parameter of an IP address (which we make sure is valid)
    if params[:ip] && (IPAddr.new(params[:ip]) rescue false)
      @ip = params[:ip]
      @search_logs = @search_logs.where('client_ip = inet ?', @ip)
    end
  end
end
