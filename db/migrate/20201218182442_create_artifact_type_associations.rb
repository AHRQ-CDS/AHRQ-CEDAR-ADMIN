class CreateArtifactTypeAssociations < ActiveRecord::Migration[6.0]
  def change
    create_table :artifact_type_associations do |t|
      t.references :artifact, null: false, foreign_key: true
      t.references :artifact_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
