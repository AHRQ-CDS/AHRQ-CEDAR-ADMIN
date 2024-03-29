# frozen_string_literal: true

# Search statistics controller
class SearchStatsController < ApplicationController
  def index
    # List of IP addresses that we should not include in statistics
    @exclude_ips = (params[:exclude_ips] || '').split(',')
    # Reject anything that doesn't look like an IP address (either v4 or v6)
    @exclude_ips.select! { |ip| IPAddr.new(ip) rescue false } # rubocop:disable Style/RescueModifier

    # The date range we should show statistics for, with a default of the last 30 days
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Time.zone.today - 30.days
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.today

    # The searches that happened in the selected date range (making sure we include all times during the end day)
    @searches = SearchLog.where('start_time >= ? AND start_time <= ?', @start_date, @end_date + 1.day)

    # Update the query with the IP addresses that should not be included
    # TODO: there must be a cleaner way to do this... issue is that conversion to inet doesn't play nice with bound expressions
    @exclude_ips.each do |exclude_ip|
      # We use the <<= "contained within or equals" operator to allow ranges, e.g., 192.168.1.0/24
      @searches = @searches.where.not('client_ip <<= inet ?', exclude_ip)
    end

    # Generate various counts, averages, and per-day figures
    @search_count = @searches.count
    @searches_per_day = @search_count / [(@end_date - @start_date).round, 1].max
    @average_time = @searches.average('end_time - start_time').round(3) if @search_count.positive?
    @searches_by_day = @searches.group_by_day(:start_time).count

    # Pull out the IP addresses that have performed searches
    @ip_addresses = @searches.group(:client_ip).count
    @top_ip_addresses = @ip_addresses.sort_by { |_key, value| value }.reverse[0, 20]

    # TODO: consider reporting on artifact clicks during the selected time period
  end
end
