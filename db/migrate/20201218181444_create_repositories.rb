class CreateRepositories < ActiveRecord::Migration[6.0]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :fhir_id
      t.string :home_page

      t.timestamps
    end

    add_index :repositories, :fhir_id, :using => :btree, :name => 'index_artifacts_on_fhir_id'
  end
end
