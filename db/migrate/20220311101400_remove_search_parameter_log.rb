class RemoveSearchParameterLog < ActiveRecord::Migration[6.0]
  def change
    drop_table :search_parameter_logs do |t|
      t.references :search_log, null: false, foreign_key: true
      t.string :name
      t.string :value
    end
  end
end
