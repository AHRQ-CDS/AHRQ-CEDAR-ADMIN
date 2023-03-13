# frozen_string_literal: true

# ImportRun helper to provide daily totals when multiple imports are run at once
module ImportRunHelper
  # Take a Hash of ImportRuns grouped by :start_time and create corresponding summarries
  def create_run_summaries(runs)
    runs.transform_values do |irs|
      ImportRun.new(total_count: irs.sum(&:total_count), new_count: irs.sum(&:new_count),
                    update_count: irs.sum(&:update_count), delete_count: irs.sum(&:delete_count))
    end
  end
end
