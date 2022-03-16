class AddRepositoryResultsToSearchLog < ActiveRecord::Migration[6.0]
  def change
    add_column :search_logs, :repository_results, :jsonb, default: {}
  end
end
