# frozen_string_literal: true

# Functionality for importing metadata from web pages
module PageScraper
  # Process an individual HTML page or PDF to extract metadata
  def extract_metadata(page_url)
    response = Faraday.get page_url.strip
    if response.status != 200
      Rails.logger.warn "Page retrieval (#{page_url}) failed with status #{response.status}"
      return {}
    end

    metadata = {}
    if response.headers['content-type'].include?('text/html')
      metadata = extract_html_metadata(response.body)
    elsif response.headers['content-type'].include?('application/pdf')
      metadata = extract_pdf_metadata(response.body)
    end
    metadata
  rescue Faraday::ConnectionFailed
    # Some pages are unavailable
    Rails.logger.warn "Failed to retrieve page: #{page_url}"
    {}
  end

  def extract_html_metadata(html)
    metadata = {}
    html = Nokogiri::HTML(html)
    description_node = html.at_css('head meta[name="description"]')
    metadata[:description] = description_node['content'] unless description_node.nil?
    keywords_node = html.at_css('head meta[name="keywords"]')
    metadata[:keywords] = keywords_node['content'].split(',').collect(&:strip) unless keywords_node.nil?
    metadata
  end

  def extract_pdf_metadata(pdf)
    metadata = {}
    reader = PDF::Reader.new(StringIO.new(pdf))
    metadata[:description] = reader.info[:Subject] unless reader.info[:Subject].nil?
    metadata[:keywords] = reader.info[:Keywords].split(',').collect(&:strip) unless reader.info[:Keywords].nil?
    metadata
  end
end
