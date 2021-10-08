class AddErrorTextToImportRun < ActiveRecord::Migration[6.0]
  def change
    remove_column :import_runs, :error_count
    add_column :import_runs, :error_msgs, :jsonb, :default => []
    add_column :import_runs, :warning_msgs, :jsonb, :default => []
  end
end
