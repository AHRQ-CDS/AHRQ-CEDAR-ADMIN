class CreateConcepts < ActiveRecord::Migration[6.0]
  def change
    create_table :concepts do |t|
      t.string :canonical
      t.jsonb :synonyms, default: []

      t.timestamps
    end
    add_index :concepts, :synonyms, :using => :gin, :name => 'index_concepts_on_synonyms'
  end
end
