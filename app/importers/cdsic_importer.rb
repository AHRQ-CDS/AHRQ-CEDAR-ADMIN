# frozen_string_literal: true

# Functionality for importing data from the CDSiC repository
class CdsicImporter < CedarImporter
  repository_name 'Clinical Decision Support Innovation Collaborative'
  repository_alias 'CDSiC'
  # NOTE: holding off using configuration for home page until CDSiC import uses a more standard model
  repository_home_page 'https://cdsic.ahrq.gov/cdsic/home-page'
  repository_description 'The Clinical Decision Support Innovation Collaborative (CDSiC) is a diverse community  ' \
                         'of experts at the forefront of using technology to better engage patients in their own care.'

  include PageScraper

  def self.download_and_update!
    importer = CdsicImporter.new
    artifacts = []
    page = Rails.configuration.cdsic_index_page
    page = importer.scrape_index_page(page, artifacts) until page.nil?
    artifacts.each { |artifact| importer.process_artifact!(artifact) }
  end

  def scrape_index_page(url, artifacts)
    response = Faraday.get url
    raise "CDSiC page retrieval (#{url}) failed with status #{response.status}" unless response.status == 200

    page_uri = URI.parse(url)
    html = Nokogiri::HTML(response.body)
    html.css('div.view-cdsic-resources div.view-content div.views-row').each do |artifact_node|
      artifact_link_node = artifact_node.at_css('div.views-field-title span.field-content a')
      if artifact_link_node.nil?
        Rails.logger.warn 'Encountered CDSiC search entry with missing title and link'
        next
      end

      artifact_title = artifact_link_node.content
      next if artifact_title.downcase.include? 'charter'

      artifact_url = artifact_link_node['href']
      if artifact_url.nil?
        Rails.logger.warn "Encountered CDSiC search entry '#{artifact_title}' with missing link"
        next
      end

      artifact_uri = URI.parse(artifact_url)
      if artifact_uri.host.nil?
        artifact_uri.host = page_uri.host
        artifact_uri.scheme = page_uri.scheme
        artifact_url = artifact_uri.to_s
      end
      warning_context = "Encountered EPC entry '#{artifact_title}' with invalid date"
      published_date, warnings, published_on_precision = PageScraper.parse_and_precision(
        artifact_node.at_css('span.views-field-field-cdsic-resource-date span.field-content')&.content, warning_context, []
      )
      artifacts << {
        title: artifact_title,
        url: artifact_url,
        published_on: published_date,
        published_on_precision: published_on_precision,
        warnings: warnings
      }
    end

    next_page_node = html.at_css('nav.pager-nav li.pager__item--next a')
    return nil if next_page_node.nil? || next_page_node['href'].empty?

    page_uri.merge(next_page_node['href']).to_s
  end

  def process_artifact!(artifact)
    cedar_id = "CDSiC-#{Digest::MD5.hexdigest(artifact[:url])}"
    page_metadata = extract_metadata(artifact[:url])
    metadata = {
      remote_identifier: artifact[:url],
      title: artifact[:title] || page_metadata[:title],
      description: page_metadata[:description],
      url: artifact[:url],
      published_on: artifact[:published_on] || page_metadata[:published_on],
      published_on_precision: [artifact[:published_on_precision].to_i, page_metadata[:published_on_precision].to_i].max,
      artifact_type: 'CDSiC Artifact',
      artifact_status: page_metadata[:status] || 'active',
      keywords: page_metadata[:keywords].to_a,
      doi: page_metadata[:doi],
      warnings: artifact[:warnings].concat(page_metadata[:warnings].to_a),
      error: page_metadata[:error]
    }
    metadata.delete_if { |_k, v| v.nil? }
    update_or_create_artifact!(cedar_id, metadata)
  end
end
