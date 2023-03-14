# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class ImportReportsController < ApplicationController
  def index
    # Query all imports for display then filter for just flags in another table.
    # Split into data and grouped_data because .page does not provide the right
    # format for create_run_summaries in ImportRunHelper
    base_imports = ImportRun.order(:start_time).reverse_order

    @all_runs = base_imports.page(params[:report_page])
    @grouped_runs = @all_runs.group_by { |ir| ir.start_time.to_date }

    @flagged_runs = base_imports.where(status: 'flagged').page(params[:flagged_page])
    @grouped_flags = @flagged_runs.group_by { |ir| ir.start_time.to_date }
  end
end
