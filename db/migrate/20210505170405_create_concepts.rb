class CreateConcepts < ActiveRecord::Migration[6.0]
  def change
    create_table :concepts do |t|
      t.string :name
      t.jsonb :synonyms_text, default: []
      t.jsonb :synonyms_psql, default: []

      t.timestamps
    end
    add_index :concepts, :synonyms_psql, :using => :gin, :name => 'index_concepts_on_synonyms_psql'
  end
end
