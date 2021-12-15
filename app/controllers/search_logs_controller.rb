# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class SearchLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    @search_logs = SearchLog.order(start_time: :desc).page params[:page]
  end
end
