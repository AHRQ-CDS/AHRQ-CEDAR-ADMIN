# frozen_string_literal: true

# Functionality for populating the concepts table
class ConceptImporter
  # TODO: (if desired) make these configurable
  SYNONYM_LANGAUGES = ['ENG', 'SPA'].freeze
  SYNONYM_CODE_SYSTEMS = ['MSH', 'MEDLINEPLUS', 'SNOMEDCT_US', 'SCTSPA', 'MSHSPA', 'ICD10CM', 'RXNORM'].freeze
  SYNONYM_SUPPRESSION_FLAGS = ['N'].freeze

  def self.create_or_update_concept(umls_cui, synonyms, codes)
    synonyms = synonyms.map { |s| I18n.transliterate(s).downcase }.uniq
    Concept.find_or_initialize_by(umls_cui: umls_cui).update!(synonyms_text: synonyms, codes: codes)
  end

  def self.import_umls_mrconso(file)
    concept = ''
    synonyms = []
    codes = []
    File.foreach(file) do |line|
      fields = line.split('|')
      if fields[0] != concept && concept.present?
        create_or_update_concept(concept, synonyms, codes)
        synonyms = []
        codes = []
      end
      concept = fields[0]
      if SYNONYM_LANGAUGES.include?(fields[1]) &&
         SYNONYM_CODE_SYSTEMS.include?(fields[11]) &&
         SYNONYM_SUPPRESSION_FLAGS.include?(fields[16])
        synonyms << fields[14].downcase.strip
        if fields[11] == 'MSH' && fields[6] == 'Y'
          # only include MeSH codes for preferred terms
          codes << {
            system: fields[11].strip,
            code: fields[13].strip,
            description: fields[14].strip
          }
        end
      end
    end
    create_or_update_concept(concept, synonyms, codes)
  end
end
