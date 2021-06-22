# frozen_string_literal: true

# Functionality for populating the concepts table
class ConceptImporter
  # TODO: (if desired) make these configurable
  SYNONYM_LANGAUGES = ['ENG', 'SPA'].freeze
  SYNONYM_CODE_SYSTEMS = ['MSH', 'MEDLINEPLUS', 'SNOMEDCT_US', 'SCTSPA', 'MSHSPA', 'ICD10CM', 'RXNORM'].freeze
  SYNONYM_SUPPRESSION_FLAGS = ['N'].freeze

  CUI_COLUMN = 0
  LANG_COLUMN = 1
  PREFERRED_COLUMN = 6
  SYSTEM_COLUMN = 11
  CODE_COLUMN = 13
  CODE_DESC_COLUMN = 14
  SUPPRESS_COLUMN = 16

  def self.create_or_update_concept(umls_cui, description, synonyms, codes)
    synonyms = synonyms.map { |s| I18n.transliterate(s).downcase }.uniq
    Concept.find_or_initialize_by(umls_cui: umls_cui).update!(umls_description: description, synonyms_text: synonyms, codes: codes)
  end

  def self.import_umls_mrconso(file)
    concept = ''
    description = ''
    synonyms = []
    codes = []
    File.foreach(file) do |line|
      fields = line.split('|')
      if fields[0] != concept && concept.present?
        create_or_update_concept(concept, description, synonyms, codes)
        synonyms = []
        codes = []
        description = ''
      end
      concept = fields[CUI_COLUMN]
      description = fields[CODE_DESC_COLUMN].strip if fields[SYSTEM_COLUMN] == 'MTH' && fields[PREFERRED_COLUMN] == 'Y'
      if SYNONYM_LANGAUGES.include?(fields[LANG_COLUMN]) &&
         SYNONYM_CODE_SYSTEMS.include?(fields[SYSTEM_COLUMN]) &&
         SYNONYM_SUPPRESSION_FLAGS.include?(fields[SUPPRESS_COLUMN])
        synonyms << fields[CODE_DESC_COLUMN].downcase.strip
        if fields[SYSTEM_COLUMN] != 'MSH' || (fields[SYSTEM_COLUMN] == 'MSH' && fields[PREFERRED_COLUMN] == 'Y')
          # Only include preferred MeSH codes
          codes << {
            system: fields[SYSTEM_COLUMN].strip,
            code: fields[CODE_COLUMN].strip,
            description: fields[CODE_DESC_COLUMN].strip
          }
        end
      end
    end
    create_or_update_concept(concept, description, synonyms, codes)
  end
end
