class CreateSearchLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :search_logs do |t|
      t.string :search_params
      t.string :search_type
      t.string :sql
      t.integer :count
      t.cidr :client_ip
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
