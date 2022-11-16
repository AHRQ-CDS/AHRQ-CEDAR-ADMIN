class CleanUpConcepts < ActiveRecord::Migration[6.0]
  def up
    # Clean up all concepts that are blank (no description, synonyms, or codes)
    Concept.where(umls_description: '').where('synonyms_text = ?', '[""]').where('codes = ?', '[]').delete_all
  end
  def down
    # Can't reverse this...
  end
end
