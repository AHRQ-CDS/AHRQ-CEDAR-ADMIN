# frozen_string_literal: true

# Search statistics controller
class SearchStatsController < ApplicationController
  def index
    # List of IP addresses that we should not include in statistics
    @exclude_ips = (params[:exclude_ips] || '').split(',')
    # Reject anything that doesn't look like an IP address (either v4 or v6)
    @exclude_ips.select! { |ip| IPAddr.new(ip) rescue false }

    # The date range we should show statistics for, with a default of the last 30 days
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today - 30.days
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

    # The searches that happened oin the selected date range
    @searches = SearchLog.where('start_time >= ? AND start_time <= ?', @start_date, @end_date)

    # Update the query with the IP addresses that should not be included
    # TODO: there must be a cleaner way to do this... issue is that conversion to inet doesn't play nice with bound expressions
    @exclude_ips.each do |exclude_ip|
      @searches = @searches.where('client_ip != inet ?', exclude_ip)
    end

    # Generate various counts, averages, and per-day figures
    @search_count = @searches.count
    @searches_per_day = @search_count / [(@end_date - @start_date).round, 1].max
    @average_time = @searches.average('end_time - start_time').round(3)
    @searches_by_day = @searches.group_by_day(:start_time).count

    # Pull out the IP addresses that have performed searches
    @ip_addresses = @searches.group(:client_ip).count
    @top_ip_addresses = @ip_addresses.sort_by { |key, value| value }.reverse[0,10]

    # TODO: consider linking the IP addresses to a page that lists the searches by that IP address
    # TODO: consider reporting on artifact clicks during the selected time period
  end
end
