module SearchLogHelper

  HUMAN_READABLE_PARAMS = {
    "artifact-current-state" => "Artifact Status",
    "artifact-publisher" => "Artifact Publisher",
    "classification:text" => "Keyword Search",
    "title:contains" => "Title Free-text Search",
    "_content" => "Content Search",
    "classification" => "MeSH Code Search",
    "_lastUpdated" => "Last Updated Search",
    "page" => "Current Page",
    "_count" => "Count Per Page"
  }

  def human_readable_search_params(search_log)
    human_readable_params = Hash.new

    search_log.each do |key, value|
      if HUMAN_READABLE_PARAMS.key?(key)
        human_readable_params[HUMAN_READABLE_PARAMS[key]] = value.delete('()')
      end
    end
    human_readable_params
  end
end