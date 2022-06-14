# frozen_string_literal: true

# Functionality for importing data from the EPC repository
class EpcImporter < CedarImporter
  repository_name 'Evidence-based Practice Center Program'
  repository_alias 'EPC'
  repository_home_page Rails.configuration.epc_home_page

  include PageScraper

  def self.download_and_update!
    importer = EpcImporter.new
    page = '?search_api_fulltext=&page=0'
    page = importer.process_index_page(page) until page.nil?
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
      if artifact_link_node.nil?
        Rails.logger.warn 'Encountered EPC search entry with missing title and link'
        next
      end

      artifact_title = artifact_link_node.content
      artifact_url = artifact_link_node['href']
      if artifact_url.nil?
        Rails.logger.warn "Encountered EPC search entry '#{artifact_title}' with missing link"
        next
      elsif artifact_url.include?('uspreventiveservicestaskforce.org') || artifact_url.include?('effectivehealthcare.ahrq.gov')
        next # skip products that are hosted on other indexed repositories
      end

      artifact_uri = URI.parse(artifact_url)
      if artifact_uri.host.nil?
        page_uri = URI.parse(url)
        artifact_uri.host = page_uri.host
        artifact_uri.scheme = page_uri.scheme
        artifact_url = artifact_uri.to_s
      end
      cedar_id = "EPC-#{Digest::MD5.hexdigest(artifact_url)}"
      artifact_type = artifact.at_css('div.views-field-field-epc-type span.field-content')&.content&.strip.presence
      artifact_status = to_artifact_status(artifact_uri)
      warning_context = "Encountered EPC entry '#{artifact_title}' with invalid date"
      published_date, warnings, published_on_precision = PageScraper.parse_and_precision(
        artifact.at_css('div.views-field-field-timestamp span.field-content')&.content, warning_context, []
      )
      metadata = {
        remote_identifier: artifact_url,
        title: artifact_title,
        url: artifact_url,
        published_on: published_date,
        published_on_precision: published_on_precision,
        artifact_type: artifact_type,
        artifact_status: artifact_status,
        warnings: warnings,
        keywords: []
      }
      metadata.merge!(extract_metadata(artifact_url))
      update_or_create_artifact!(cedar_id, metadata)
      Rails.logger.info "Processed EPC artifact #{artifact_url}"
    end

    # Search results are paged, extract the path of the next page
    next_page_node = html.at_css('li.pager__item--next a')
    next_page_node ? next_page_node['href'] : nil
  end

  def to_artifact_status(artifact_uri)
    return 'unknown' if artifact_uri.host.nil?

    artifact_uri.host.start_with?('archive') ? 'archived' : 'active'
  end
end
