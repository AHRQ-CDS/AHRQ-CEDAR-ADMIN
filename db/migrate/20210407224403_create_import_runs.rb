class CreateImportRuns < ActiveRecord::Migration[6.0]
  def change
    create_table :import_runs do |t|
      t.references :repository, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.string :status
      t.string :error_message
      t.integer :total_count, :default => 0, :null => false
      t.integer :new_count, :default => 0, :null => false
      t.integer :update_count, :default => 0, :null => false
      t.timestamps
    end
  end
end
