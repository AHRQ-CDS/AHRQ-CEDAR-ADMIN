# frozen_string_literal: true

# Search logs controller that shows logs with pagination, 50 logs per page
class ImportReportsController < ApplicationController
  def index
    start_time = ImportRun.select('DISTINCT DATE(start_time) AS start_date').order(:start_date).reverse_order.map(&:start_date).last
    base_imports = ImportRun.where('DATE(start_time) >= ?', start_time).order(:start_time).reverse_order

    @flagged_runs = base_imports.where('status = ?', 'flagged').page(params[:flagged_page])
    @flagged_tabular = @flagged_runs.group_by { |ir| ir.start_time.to_date }
    @flagged_summaries = create_summaries(@flagged_tabular)

    @all_runs = base_imports.page(params[:report_page])
    @all_tabular = @all_runs.group_by { |ir| ir.start_time.to_date }
    @all_summaries = create_summaries(@all_tabular)
  end

  private
  def create_summaries(runs)
    runs.transform_values do |irs|
      ImportRun.new(total_count: irs.sum(&:total_count), new_count: irs.sum(&:new_count),
                    update_count: irs.sum(&:update_count), delete_count: irs.sum(&:delete_count))
    end
  end

end
