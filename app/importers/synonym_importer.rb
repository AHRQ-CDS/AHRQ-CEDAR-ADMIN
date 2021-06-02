# frozen_string_literal: true

# Functionality for populating the concepts table
class SynonymImporter
  # TBD if desired: make language and source terminology (e.g. MeSH) configurable
  SYNONYM_LANGAUGES = ['ENG', 'SPA'].freeze

  def self.import_umls_mrconso(file)
    concept = ''
    synonyms = []
    File.foreach(file) do |line|
      fields = line.split('|')
      if fields[0] != concept && concept.present?
        Concept.create!(name: concept, synonyms_text: synonyms.uniq) if synonyms.size > 1
        synonyms = []
      end
      concept = fields[0]
      synonyms << fields[14].downcase.strip if SYNONYM_LANGAUGES.include? fields[1]
    end
    Concept.create!(name: concept, synonyms_text: synonyms.uniq) if synonyms.size > 1
  end
end
