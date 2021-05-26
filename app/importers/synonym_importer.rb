# frozen_string_literal: true

# Functionality for populating the concepts table
class SynonymImporter
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
  end

  def self.import_mesh(file, canonical_prefix, synonym_prefix)
    canonical_line_start = "#{canonical_prefix} = "
    synonym_line_start = "#{synonym_prefix} = "
    concept = ''
    synonyms = []
    File.foreach(file) do |line|
      if line.strip == '*NEWRECORD' && concept.present?
        synonyms << concept unless synonyms.include? concept
        synonyms.uniq!
        Concept.create!(name: concept, synonyms_text: synonyms) if synonyms.size > 1
        concept = ''
        synonyms = []
      end
      if line.starts_with? canonical_line_start
        concept = line.delete_prefix(canonical_line_start).downcase.strip
      elsif line.starts_with? synonym_line_start
        synonyms << line.delete_prefix(synonym_line_start).split('|')[0].downcase.strip
      end
    end
  end
end
