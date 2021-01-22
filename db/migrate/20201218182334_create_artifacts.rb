class CreateArtifacts < ActiveRecord::Migration[6.0]
  def change
    create_table :artifacts do |t|
      t.string :title
      t.text :description
      t.references :repository, null: false, foreign_key: true
      t.string :url
      t.string :remote_identifier
      t.string :artifact_type
      t.date :published_on
      t.jsonb :keywords, default: []
      t.jsonb :mesh_keywords, default: []

      t.timestamps
    end
    # TODO: Confirm that these are reasonable indexes for how we wind up using keywords
    add_index :artifacts, :keywords, :using => :gin, :name => 'index_artifacts_on_keywords'
    add_index :artifacts, :mesh_keywords, :using => :gin, :name => 'index_artifacts_on_mesh_keywords'
  end
end
