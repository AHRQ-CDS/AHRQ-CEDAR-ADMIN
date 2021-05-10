class AddDeleteCountToImportRun < ActiveRecord::Migration[6.0]
  def change
    add_column :import_runs, :delete_count, :integer, :default => 0, :null => false
  end
end
