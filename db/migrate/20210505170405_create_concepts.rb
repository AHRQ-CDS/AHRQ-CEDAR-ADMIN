class CreateConcepts < ActiveRecord::Migration[6.0]
  def change
    create_table :concepts do |t|
      t.string :umls_cui
      t.jsonb :synonyms_text, default: []
      t.jsonb :synonyms_psql, default: []
      t.jsonb :codes, default: []

      t.timestamps
    end

    create_table "artifacts_concepts", id: false do |t|
      t.belongs_to :concept
      t.belongs_to :artifact
    end

    add_index :concepts, :umls_cui, :unique => true, :name => 'index_concepts_on_umls_cui'
    add_index :concepts, :synonyms_text, :using => :gin, :name => 'index_concepts_on_synonyms_text'
    add_index :concepts, :synonyms_psql, :using => :gin, :name => 'index_concepts_on_synonyms_psql'
    add_index :concepts, :codes, :using => :gin, :name => 'index_concepts_on_codes'
  end
end
