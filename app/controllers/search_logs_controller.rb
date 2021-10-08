# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class SearchLogsController < ApplicationController
  def index
    @search_logs = SearchLog.order(:start_time).page params[:page]
  end
end
