# frozen_string_literal: true

# Functionality for populating the concepts table
# UMLS MRCONSO file format: https://www.ncbi.nlm.nih.gov/books/NBK9685/table/ch03.T.concept_names_and_sources_file_mr/
class ConceptImporter
  # TODO: (if desired) make these configurable
  SYNONYM_LANGAUGES = ['ENG', 'SPA'].freeze
  SYNONYM_CODE_SYSTEMS = ['MSH', 'MEDLINEPLUS', 'SNOMEDCT_US', 'SCTSPA', 'MSHSPA', 'ICD10CM', 'RXNORM'].freeze
  SYNONYM_SUPPRESSION_FLAGS = ['N'].freeze
  INCLUDED_TERM_TYPES = {
    'MSH' => ['MH', 'ET', 'PM'],
    'MSHSPA' => ['MH', 'ET', 'PM'],
    'SNOMEDCT_US' => ['PT'],
    'SCTSPA' => ['PT'],
    'ICD10CM' => ['PT'],
    'RXNORM' => ['IN']
  }.freeze

  CUI_COLUMN = 0
  LANG_COLUMN = 1
  PREFERRED_COLUMN = 6
  SYSTEM_COLUMN = 11
  TERM_TYPE_COLUMN = 12
  CODE_COLUMN = 13
  CODE_DESC_COLUMN = 14
  SUPPRESS_COLUMN = 16

  def self.create_or_update_concept(umls_cui, description, synonyms, codes)
    description = synonyms[0] if description.blank? && synonyms.present?
    synonyms << description
    synonyms = synonyms.map { |s| I18n.transliterate(s).downcase }.uniq

    # Skip creating any that are blank
    return if description.blank? && synonyms.all?(&:blank?) && codes.all?(&:blank?)

    Concept.find_or_initialize_by(umls_cui: umls_cui).update!(umls_description: description, synonyms_text: synonyms, codes: codes)
  end

  def self.import_umls_mrconso(file)
    concept = ''
    mth_description = ''
    synonyms = []
    codes = []
    assigned_codes = {}
    File.foreach(file) do |line|
      fields = line.split('|')
      if fields[0] != concept && concept.present?
        create_or_update_concept(concept, mth_description, synonyms, codes)
        synonyms = []
        codes = []
        mth_description = ''
        assigned_codes = {}
      end
      concept = fields[CUI_COLUMN].strip
      code_system = fields[SYSTEM_COLUMN].strip
      code = fields[CODE_COLUMN].strip
      preferred = fields[PREFERRED_COLUMN].strip
      description = fields[CODE_DESC_COLUMN].strip
      mth_description = description if code_system == 'MTH' && preferred == 'Y'
      if SYNONYM_LANGAUGES.include?(fields[LANG_COLUMN].strip) &&
         SYNONYM_CODE_SYSTEMS.include?(code_system) &&
         SYNONYM_SUPPRESSION_FLAGS.include?(fields[SUPPRESS_COLUMN])
        synonyms << description.downcase.strip
        # Avoid duplication of codes
        code_to_assign = "#{code_system}_#{code}"
        if assigned_codes.exclude?(code_to_assign) &&
           INCLUDED_TERM_TYPES.include?(code_system) &&
           INCLUDED_TERM_TYPES[code_system].include?(fields[TERM_TYPE_COLUMN].strip)
          codes << {
            system: code_system,
            code: code,
            description: description
          }
          assigned_codes[code_to_assign] = true
        end
      end
    end
    create_or_update_concept(concept, mth_description, synonyms, codes) if synonyms.present?
  end
end
