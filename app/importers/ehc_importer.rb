# frozen_string_literal: true

# Functionality for importing data from the EHC repository
class EhcImporter
  include PageScraper

  def self.download_and_update!
    importer = EhcImporter.new
    page = '/products'
    page = importer.process_index_page(page) until page.nil?
  end

  def initialize
    @ehc_repository = Repository.where(name: 'EHC').first_or_create!(home_page: Rails.configuration.ehc_home_page)
  end

  # Import a single page of search results and return the path to the next page or nil
  # if this is the final page.
  def process_index_page(page)
    url = "#{Rails.configuration.ehc_base_url}#{page}"
    response = Faraday.get url
    raise "EHC page retrieval (#{url}) failed with status #{response.status}" unless response.status == 200

    # Search results are structured as an HTML list as follows:
    # <li class="ehc-item">
    #   <div class="item-content">
    #     <div class="item-header">
    #       <a href="/products/stroke-atrial-fibrillation/research">Stroke Prevention in Atrial Fibrillation</a>
    #     </div>
    #     <div class="item-meta">
    #       <div class="item-type">
    #         <span class="field-content">Systematic Review</span>
    #       </div>
    #       <div class="item-type">
    #         <span class="field-content badge badge-default">Archived</span>
    #       </div>
    #       <div class="item-date">
    #         <span class="field-content">August 23, 2013</span>
    #       </div>
    #     </div>
    #   </div>
    # </li>
    html = Nokogiri::HTML(response.body)
    html.css('div.item-content').each do |artifact|
      artifact_link_node = artifact.at_css('div.item-header a')
      if artifact_link_node.nil?
        Rails.logger.warn 'Encountered EHC search entry with missing title and link'
        next
      end

      artifact_title = artifact_link_node.content
      artifact_path = artifact_link_node['href']
      if artifact_path.nil?
        Rails.logger.warn "Encountered EHC search entry '#{artifact_title}' with missing link"
        next
      end

      cedar_id = ['EHC', artifact_path.split('/').reject(&:empty?)].flatten.join('-')
      artifact_url = "#{Rails.configuration.ehc_base_url}#{artifact_path}"
      artifact_type_nodes = artifact.css('div.item-meta div.item-type span.field-content').to_a
      if artifact_type_nodes.size >= 2
        artifact_type = artifact_type_nodes[0].content
        artifact_status = artifact_type_nodes[1].content
        artifact_status = 'Active' if artifact_status.empty?
      else
        Rails.logger.warn "Encountered EHC search entry '#{artifact_title}' with missing type or status"
      end

      artifact_date_str = artifact.at_css('div.item-meta div.item-date span.field-content')&.content
      begin
        artifact_date = Date.parse(artifact_date_str) unless artifact_date_str.nil?
      rescue Date::Error
        Rails.logger.warn "Encountered EHC search entry '#{artifact_title}' with invalid date '#{artifact_date_str}'"
      end

      metadata = {
        remote_identifier: artifact_path,
        repository: @ehc_repository,
        title: artifact_title,
        url: artifact_url,
        published_on: artifact_date,
        artifact_type: artifact_type,
        artifact_status: to_cedar_status(artifact_status),
        keywords: [],
        mesh_keywords: []
      }
      metadata.merge!(extract_metadata(artifact_url))
      Artifact.update_or_create!(cedar_id, metadata)
      Rails.logger.info "Processed EHC artifact #{artifact_url}"
    end

    # Search results are paged, extract the path of the next page from the following
    # HTML structure
    # <div class="pagination pagination-sm" id="results_paginate">
    #   <li class="page-item disabled">
    #     <span class="page-link">Previous</span>
    #   </li>
    #   <li class="page-item">
    #     <span class="page-link">Page 1 of 38</span>
    #   </li>
    #   <li class="page-item">
    #     <a class="page-link" href="/products?page=1">Next</a>
    #   </li>
    # </div>
    next_page_node = html.css('div.pagination li.page-item').last
    next_page_link = next_page_node.at_css('a.page-link')
    next_page_link ? next_page_link['href'] : nil
  end

  def to_cedar_status(ehc_status)
    case ehc_status
    when 'Archived'
      'retired'
    else
      'active'
    end
  end
end
