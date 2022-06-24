# frozen_string_literal: true

require 'date_time_precision/lib'

# Functionality for importing metadata from web pages
module PageScraper
  KEYWORD_SEPARATOR = /[,;]/.freeze

  # Process an individual HTML page or PDF to extract metadata
  def extract_metadata(page_url)
    return {} if page_url.empty?
    
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
      metadata = extract_html_metadata(response.body, page_url)
    elsif response.headers['content-type'].include?('application/pdf')
      metadata = extract_pdf_metadata(response.body)
    end
    metadata
  rescue Faraday::ConnectionFailed, FaradayMiddleware::RedirectLimitReached => e
    # Some pages are unavailable
    error_msg = "Failed to retrieve page (#{page_url}): #{e.message}"
    Rails.logger.warn error_msg
    { error: error_msg }
  end

  def extract_html_metadata(html, page_url)
    metadata = {}
    warnings = []
    html = Nokogiri::HTML(html)
    description_node =
      html.at_css('meta[name="description"]') ||
      html.at_css('meta[name="DCTERMS.description"]')
    metadata[:description] = description_node['content'] unless description_node.nil?
    metadata[:keywords] = []
    keywords_node =
      html.at_css('meta[name="keywords"]') ||
      html.at_css('meta[name="Keywords"]')
    if keywords_node.present?
      metadata[:keywords].concat(keywords_node['content'].split(KEYWORD_SEPARATOR).collect do |keyword|
                                   keyword.strip.gsub(/^and /, '')
                                 end)
    end
    if html.at_css('meta[name="citation_keyword"]').present?
      metadata[:keywords].concat(html.css('meta[name="citation_keyword"]').collect { |keyword_node| keyword_node['content'] })
    end
    # JAMA Network pages
    metadata[:keywords].concat(html.css('a.related-topic').collect(&:content)) if html.at_css('a.related-topic').present?
    # AAFP pages
    metadata[:keywords].concat(html.css('ul.relatedContent a').collect(&:content)) if html.at_css('ul.relatedContent a').present?

    # DOI
    doi_node = html.at_css('meta[name="citation_doi"]')
    metadata[:doi] = doi_node['content'] unless doi_node.nil?

    # Publication date
    date_node =
      html.at_css('meta[name="DCTERMS.issued"]') ||
      html.at_css('meta[name="DCTERMS.created"]') ||
      html.at_css('meta[name="DC.Date"]') ||
      html.at_css('meta[name="DC.date"]') ||
      html.at_css('meta[name="citation_publication_date"]') ||
      html.at_css('meta[name="citation_date"]')

    date = parse_by_core_format(date_node['content']) unless date_node.nil?
    if date_node.nil?
      warnings << "Encountered #{page_url} with missing date"
    elsif date.nil?
      warnings << "Encountered #{page_url} with invalid date"
    else
      metadata[:published_on] = date
      metadata[:published_on_precision] = DateTimePrecision.precision(date_node['content'].split(/[-, :T]/).map(&:to_i))
    end
    metadata[:warnings] = warnings
    metadata
  end

  def extract_pdf_metadata(pdf)
    metadata = {}
    reader = PDF::Reader.new(StringIO.new(pdf))
    metadata[:description] = reader.info[:Subject] unless reader.info[:Subject].nil?
    metadata[:keywords] = reader.info[:Keywords].split(KEYWORD_SEPARATOR).collect(&:strip) unless reader.info[:Keywords].nil?
    pdf_date_str = reader.info[:ModDate] || reader.info[:CreationDate]
    # PDF date format is "D:20150630104759-04'00'"
    warning_context = 'Encountered pdf with invalid date'
    metadata[:published_on], metadata[:warnings], metadata[:published_on_precision] = parse_and_precision(pdf_date_str[2..9], warning_context, [])
    metadata
  end

  # DateTimePrecision is from date_time_precision/lib
  def parse_and_precision(input, warning_context, messages)
    case input
    when String
      begin
        date = Date.parse(input)
        precision = DateTimePrecision.precision(Date._parse(input))
      rescue Date::Error
        messages << "#{warning_context}, #{input}"
      end
    when nil
      date = nil
      precision = 0
    end
    [date, messages, precision]
  end

  # See for formats: https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/date/
  def parse_by_core_format(input)
    ['%Y-%m-%d', '%Y-%m', '%Y', '%F %T', '%FT%H:%M:%S', '%Y-%m-%dT%H:%M:%S%z'].each do |date_format|
      return Date.strptime(input, date_format)
    rescue Date::Error
      next
    end
  end

  module_function :parse_and_precision
end
