class CreateArtifacts < ActiveRecord::Migration[6.0]
  def change
    create_table :artifacts do |t|
      t.string :title
      t.text :description
      t.references :repository, null: false, foreign_key: true
      t.string :url
      t.string :remote_identifier
      t.string :artifact_type
      t.date :published

      t.timestamps
    end
  end
end
