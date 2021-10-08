class SearchLogsController < ApplicationController
  def index
    @search_logs = SearchLog.order(:start_time).page params[:page]
  end
end