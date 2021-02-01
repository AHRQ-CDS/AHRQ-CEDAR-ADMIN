# frozen_string_literal: true

# Functionality for importing data from the EPC repository
class EpcImporter
  include PageScraper

  def self.download_and_update!
    importer = EpcImporter.new
    page = '?search_api_fulltext=&page=0'
    page = importer.process_index_page(page) until page.nil?
    importer.remove_obsolete_entries!
    importer.process_product_pages!
  end

  def initialize
    @epc_repository = Repository.where(name: 'EPC').first_or_create!(home_page: Rails.configuration.epc_home_page)
    @found_ids = {}
  end

  # Import a single page of search results and return the path to the next page or nil
  # if this is the final page.
  def process_index_page(page)
    url = "#{Rails.configuration.epc_base_url}#{page}"
    response = Faraday.get url
    raise "EPC page retrieval (#{url}) failed with status #{response.status}" unless response.status == 200

    # Search results are structured as a set of HTML divs as follows:
    # <div class="view-content row">
    #   <div class="col-12">
    #     <div class="views-row">
    #       <div class="views-field views-field-nid"></div>
    #       <div class="views-field views-field-title">
    #         <span class="field-content">
    #           <a href="https://effectivehealthcare.ahrq.gov/products/pediatric-cancer-survivorship/protocol">
    #             Disparities and Barriers for Pediatric Cancer Survivorship Care
    #           </a>
    #       </span>
    #       </div>
    #       <div class="views-field views-field-field-timestamp">
    #         <span class="field-content">Date: October 2020</span>
    #       </div>
    #       <div class="views-field views-field-field-epc-type">
    #         <span class="views-label views-label-field-epc-type">EPC Type:</span> <span class="field-content">In Progress</span>
    #       </div>
    #       <div class="views-field views-field-field-epc-name">
    #         <span class="views-label views-label-field-epc-name">EPC Name:</span> <span class="field-content">AHRQ</span>
    #       </div>
    #     </div>
    #   </div>
    # </div>
    html = Nokogiri::HTML(response.body)
    html.css('div.view-content div.views-row').each do |artifact|
      artifact_link_node = artifact.at_css('div.views-field-title span.field-content a')
      artifact_title = artifact_link_node.content
      artifact_url = artifact_link_node['href']
      artifact_uri = URI.parse(artifact_url)
      artifact_path = artifact_uri.path
      cedar_id = ['EPC', artifact_path.split('/').reject(&:empty?)].flatten.join('-')
      @found_ids[cedar_id] = artifact_url
      artifact_type = artifact.at_css('div.views-field-field-epc-type span.field-content')&.content
      artifact_status = to_artifact_status(artifact_uri)
      artifact_date_str = artifact.at_css('div.views-field-field-timestamp  span.field-content')&.content
      artifact_date = artifact_date_str.nil? ? nil : Date.parse(artifact_date_str) # Date.parse ignores the 'Date: ' prefix in the field
      Artifact.update_or_create!(
        cedar_id,
        remote_identifier: artifact_path,
        repository: @epc_repository,
        title: artifact_title,
        url: artifact_url,
        published_on: artifact_date,
        artifact_type: artifact_type,
        artifact_status: artifact_status,
        keywords: [],
        mesh_keywords: []
      )
      Rails.logger.info "Processed EPC page #{url}"
    end

    # Search results are paged, extract the path of the next page
    next_page_node = html.at_css('li.pager__item--next a')
    next_page_node ? next_page_node['href'] : nil
  end

  # Remove any EPC entries that were not found in the completed index run
  def remove_obsolete_entries!
    Artifact.where(repository: @epc_repository).where.not(cedar_identifier: @found_ids.keys).destroy_all
  end

  def process_product_pages!
    @found_ids.each_pair do |cedar_id, page_url|
      extract_description(cedar_id, page_url)
    end
  end

  def to_artifact_status(artifact_uri)
    return 'unknown' if artifact_uri.host.nil?

    artifact_uri.host.start_with?('archive') ? 'retired' : 'active'
  end
end
