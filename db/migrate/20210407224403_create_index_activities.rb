class CreateIndexActivities < ActiveRecord::Migration[6.0]
  def change
    create_table :index_activities do |t|
      t.references :repository, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.string :status
      t.string :error_message
      t.integer :index_count
      t.integer :new_count
      t.integer :update_count
      t.timestamps
    end
  end
end
