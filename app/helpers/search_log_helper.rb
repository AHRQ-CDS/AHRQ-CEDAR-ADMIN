# frozen_string_literal: true

# Search helper that maps search params to a human-readable format and returns the search back as a hash
module SearchLogHelper
  HUMAN_READABLE_PARAMS = {
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

  # Converts selected concept codings in search log to a human readable version
  #
  # @param string of code system references for single concept delimited by
  # comma. Format for a each is "<code system url>|<code>|<display>."
  #
  # @return array of human readable codes corresponding to selected concept
  def human_readable_code_search(code_search)
    readable_codes = []
    code_search = code_search[0...-1] # remove trailing .
    references = code_search.split('.,')
    references.each do |ref|
      coding = ref.split('|')
      display = coding[2].nil? ? '' : coding[2]
      readable_coding = "#{CODE_SYSTEMS[coding[0]]}: #{coding[1]} (#{display})"
      readable_codes.push(readable_coding)
    end
    readable_codes
  end
end
