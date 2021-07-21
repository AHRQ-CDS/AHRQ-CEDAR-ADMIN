class CreateSearchLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :search_logs do |t|
      t.jsonb :search_params, default: {}
      t.integer :count
      t.integer :total
      t.cidr :client_ip
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end

    create_table :search_parameter_logs do |t|
      t.references :search_log, null: false, foreign_key: true
      t.string :name
      t.string :value
    end
  end
end


