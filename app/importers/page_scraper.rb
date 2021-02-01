# frozen_string_literal: true

# Functionality for importing metadata from web pages
module PageScraper
  # Process an individual page to extract metadata
  def extract_description(cedar_identifier, page_url)
    response = Faraday.get page_url.strip
    if response.status != 200
      Rails.logger.warn "Page retrieval (#{page_url}) failed with status #{response.status}"
      return
    end
    return unless response.headers['content-type'].include?('text/html') # ignore PDFs

    html = Nokogiri::HTML(response.body)
    description_node = html.at_css('head meta[name="description"]')
    Artifact.update_or_create!(cedar_identifier, description: description_node['content']) unless description_node.nil?
  rescue Faraday::ConnectionFailed
    # Some pages are unavailable
    Rails.logger.warn "Failed to retrieve page: #{page_url}"
  end
end
