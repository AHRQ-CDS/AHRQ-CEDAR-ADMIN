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
    'Metathesaurus' => 'http://www.nlm.nih.gov/research/umls/mth',
    'MeSH' => 'http://terminology.hl7.org/CodeSystem/MSH',
    'Medline Plus' => 'http://www.nlm.nih.gov/research/umls/medlineplus',
    'SNOMED-CT' => 'http://snomed.info/sct',
    'SNOMED-CT (ESP)' => 'http://snomed.info/sct/449081005',
    'MeSH (ESP)' => 'http://www.nlm.nih.gov/research/umls/mshspa',
    'ICD-10-CM' => 'http://hl7.org/fhir/sid/icd-10-cm',
    'RxNorm' => 'http://www.nlm.nih.gov/research/umls/rxnorm'
  }.freeze

  def human_readable_search_params(search_log)
    search_log.each_with_object({}) do |(key, value), hash|
      value = value.delete('()') if HUMAN_READABLE_PARAMS.key?(key) && !value.is_a?(Array)
      hash[HUMAN_READABLE_PARAMS[key]] = value
    end
  end

  def seperate_code_systems(code_searches)
    hash = Hash.new { |k, v| k[v] = [] }
    # For each search, sort it intro the above bucket based off system's url id
    code_searches.each do |item|
      CODE_SYSTEMS.each do |key, value|
        hash[key].push(item) if item.include? value
      end
    end
    hash
  end
end
