# frozen_string_literal: true

# Functionality for importing metadata from web pages
module PageScraper
  KEYWORD_SEPARATOR = /[,;]/.freeze

  # Process an individual HTML page or PDF to extract metadata
  def extract_metadata(page_url)
    connection = Faraday.new page_url.strip do |con|
      con.use FaradayMiddleware::FollowRedirects, limit: 5
      con.adapter Faraday.default_adapter
    end
    response = connection.get
    if response.status != 200
      error_msg = "Page retrieval (#{page_url}) failed with status #{response.status}"
      Rails.logger.warn error_msg
      return { error: error_msg }
    end

    metadata = {}
    if response.headers['content-type'].include?('text/html')
      metadata = extract_html_metadata(response.body)
    elsif response.headers['content-type'].include?('application/pdf')
      metadata = extract_pdf_metadata(response.body)
    end
    metadata
  rescue Faraday::ConnectionFailed, FaradayMiddleware::RedirectLimitReached
    # Some pages are unavailable
    error_msg = "Failed to retrieve page: #{page_url}"
    Rails.logger.warn error_msg
    { error: error_msg }
  end

  def extract_html_metadata(html)
    metadata = {}
    html = Nokogiri::HTML(html)
    description_node =
      html.at_css('head meta[name="description"]') ||
      html.at_css('head meta[name="DCTERMS.description"]')
    metadata[:description] = description_node['content'] unless description_node.nil?
    metadata[:keywords] = []
    keywords_node =
      html.at_css('head meta[name="keywords"]') ||
      html.at_css('head meta[name="Keywords"]')
    metadata[:keywords].concat(keywords_node['content'].split(KEYWORD_SEPARATOR).collect(&:strip)) if keywords_node.present?
    if html.at_css('head meta[name="citation_keyword"]').present?
      metadata[:keywords].concat(html.css('head meta[name="citation_keyword"]').collect { |keyword_node| keyword_node['content'] })
    end
    # JAMA Network pages
    metadata[:keywords].concat(html.css('a.related-topic').collect(&:content)) if html.at_css('a.related-topic').present?
    # AAFP pages
    metadata[:keywords].concat(html.css('ul.relatedContent a').collect(&:content)) if html.at_css('ul.relatedContent a').present?
    date_node =
      html.at_css('head meta[name="citation_publication_date"]') ||
      html.at_css('head meta[name="citation_date"]') ||
      html.at_css('head meta[name="DCTERMS.issued"]') ||
      html.at_css('head meta[name="DCTERMS.created"]') ||
      html.at_css('head meta[name="DC.Date"]') ||
      html.at_css('head meta[name="DC.date"]')
    begin
      metadata[:published_on] = Date.parse(date_node['content']) unless date_node.nil?
    rescue Date::Error
      # ignore malformed dates
    end
    metadata
  end

  def extract_pdf_metadata(pdf)
    metadata = {}
    reader = PDF::Reader.new(StringIO.new(pdf))
    metadata[:description] = reader.info[:Subject] unless reader.info[:Subject].nil?
    metadata[:keywords] = reader.info[:Keywords].split(KEYWORD_SEPARATOR).collect(&:strip) unless reader.info[:Keywords].nil?
    pdf_date_str = reader.info[:ModDate] || reader.info[:CreationDate]
    # PDF date format is "D:20150630104759-04'00'"
    metadata[:published_on] = Date.parse(pdf_date_str[2..9]) unless pdf_date_str.nil?
    metadata
  end
end
