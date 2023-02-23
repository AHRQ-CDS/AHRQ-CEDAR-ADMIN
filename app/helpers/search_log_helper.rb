# frozen_string_literal: true

# Search helper that maps search params to a human-readable format and returns the search back as a hash
module SearchLogHelper
  HUMAN_READABLE_PARAMS = {
    'artifact-type' => 'Artifact Type',
    'artifact-current-state' => 'Artifact Status',
    'artifact-publisher' => 'Artifact Publisher',
    'classification:text' => 'Keyword Search',
    'title:contains' => 'Title Free-text Search',
    '_content' => 'Content Search',
    'classification' => 'Code Search',
    '_lastUpdated' => 'Last Updated Search',
    'page' => 'Current Page',
    '_count' => 'Count Per Page'
  }.freeze

  CODE_SYSTEMS = {
    'http://www.nlm.nih.gov/research/umls/mth' => 'UMLS MTH',
    'http://hl7.org/fhir/sid/icd-10-cm' => 'ICD-10-CM',
    'http://www.nlm.nih.gov/research/umls/medlineplus' => 'Medline Plus',
    'http://terminology.hl7.org/CodeSystem/MSH' => 'MeSH',
    'http://www.nlm.nih.gov/research/umls/mshspa' => 'MeSH (ESP)',
    'http://snomed.info/sct' => 'SNOMED-CT',
    'http://snomed.info/sct/449081005' => 'SNOMED-CT (ESP)',
    'http://www.nlm.nih.gov/research/umls/rxnorm' => 'RxNorm'
  }.freeze

  def human_readable_search_params(search_log)
    search_log.each_with_object({}) do |(key, value), hash|
      value = value.delete('()') if HUMAN_READABLE_PARAMS.key?(key) && !value.is_a?(Array)
      hash[HUMAN_READABLE_PARAMS[key]] = value
    end
  end

  # Parses selected concept codings in search log to systems + codes
  #
  # @param string of code system references for single concept delimited by
  # comma. Format for a each is "<code system url>|<code>"
  #
  # @return array of parsed codes corresponding to selected concept
  def parse_code_search(code_search)
    parsed_codes = []
    references = code_search.split(',')
    references.each do |ref|
      coding = ref.split('|')
      parsed_codes.push([CODE_SYSTEMS[coding[0]] || '[Unknown Code System]', coding[1] || '[No Code]'])
    end
    parsed_codes
  end

  # @param Choose 1st code from (code system, code) pair of concept search param
  #
  # @return umls_description for first result (should only be 1)
  def get_code_description(code_search)
    code = code_search.split(',')[0].split('|')[1]
    return 'No Code Provided' if code.blank?

    concept = Concept.where('codes @> ?', "[{\"code\":\"#{code}\"}]").first
    concept&.umls_description || "Unrecognized Code #{code}"
  end
end
