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

  def human_readable_search_params(search_log)
    search_log.each_with_object({}) do |(key, value), hash|
      value = value.delete('()') if HUMAN_READABLE_PARAMS.key?(key) && !value.is_a?(Array)
      hash[HUMAN_READABLE_PARAMS[key]] = value
    end
  end
end
