# frozen_string_literal: true

require 'date_time_precision/lib'

# Functionality for importing metadata from web pages
module PageScraper
  KEYWORD_SEPARATOR = /[,;]/.freeze
  DATE_FORMATS = ['%Y-%m-%d', '%Y-%m', '%Y', '%F %T', '%FT%H:%M:%S', '%Y-%m-%dT%H:%M:%S%z', '%B %Y'].freeze
  BLOCKED_SITES = [/jamanetwork\.com/].freeze

  # Process an individual HTML page or PDF to extract metadata
  def extract_metadata(page_url)
    return {} if page_url.empty?
    return {} if BLOCKED_SITES.any? { |site| site.match page_url }
    return extract_nih_bookshelf_metadata(page_url) if page_url.match?(%r{ncbi\.nlm\.nih\.gov/books/NBK})

    response = get_url(page_url)
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
  rescue Faraday::ConnectionFailed, Faraday::FollowRedirects::RedirectLimitReached => e
    # Some pages are unavailable
    error_msg = "Failed to retrieve page (#{page_url}): #{e.message}"
    Rails.logger.warn error_msg
    { error: error_msg }
  end

  def get_url(url)
    connection = Faraday.new url.strip do |con|
      con.response :follow_redirects, limit: 5
    end
    connection.get
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

    metadata[:keywords].concat(html.css('meta[name="citation_keyword"]').pluck('content')) if html.at_css('meta[name="citation_keyword"]').present?

    # JAMA Network pages
    metadata[:keywords].concat(html.css('a.related-topic').collect(&:content)) if html.at_css('a.related-topic').present?
    # AAFP pages
    metadata[:keywords].concat(html.css('ul.relatedContent a').collect(&:content)) if html.at_css('ul.relatedContent a').present?
    # DOI
    doi_node = html.at_css('meta[name="citation_doi"]')
    metadata[:doi] = doi_node['content'] unless doi_node.nil?

    # Check for EPC archived status
    metadata[:artifact_status] = 'archived' if html.css('meta[name="warning"]').any? { |warning| warning['content']&.include? 'historical reference only' }

    # Publication date
    date_node =
      html.at_css('meta[name="DCTERMS.issued"]') ||
      html.at_css('meta[name="DCTERMS.created"]') ||
      html.at_css('meta[name="DC.Date"]') ||
      html.at_css('meta[name="DC.date"]') ||
      html.at_css('meta[name="citation_publication_date"]') ||
      html.at_css('meta[name="citation_date"]') ||
      html.at_css('meta[name="datereviewed"]') ||
      html.at_css('meta[name="datecreated"]') ||
      html.at_css('time') ||
      html.at_css('div[id="page-created"]') ||
      html.at_css('span[id="lblTitleDate"]') ||
      html.at_css('span[id="lblTitleId"]') ||
      html.css('div[id="mainContent"] div[id="centerContent"] p').find do |p|
        parse_by_core_format(p.content, formats: ['%Y-%m-%d', '%B %Y']).present?
      end

    date_content = date_node['content'] || date_node['datetime'] || date_node.content unless date_node.nil?
    date_content.delete!('Page originally created ') if date_content&.include?('Page originally created ')

    date = parse_by_core_format(date_content) unless date_content.nil?
    if date_content.nil?
      warnings << "Encountered #{page_url} with missing date"
    elsif date.nil?
      warnings << "Encountered #{page_url} with invalid date: #{date_content}"
    else
      metadata[:published_on] = date
      metadata[:published_on_precision] = DateTimePrecision.precision(date_content.split(/[-, :T]/).map(&:to_i))
    end
    metadata[:warnings] = warnings
    metadata
  end

  def extract_pdf_metadata(pdf)
    metadata = {}
    reader = PDF::Reader.new(StringIO.new(pdf))
    metadata[:title] = reader.info[:Title] unless reader.info[:Title].nil?
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
        if input.present?
          date = Date.parse(input)
          precision = DateTimePrecision.precision(Date._parse(input))
        else
          date = nil
          precision = 0
        end
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
  def parse_by_core_format(input, formats: DATE_FORMATS)
    formats.each do |date_format|
      return Date.strptime(input, date_format)
    rescue Date::Error
      next
    end
    nil
  end

  def extract_nih_bookshelf_metadata(url)
    # the NIH bookshelf site blocks bulk downloads but provides an alternate site to obtain metadata
    # extract the book_if from the original URL and use it to create a new URL for the metadata
    book_id_match = url.match(%r{/books/NBK(\d+)})
    return {} if book_id_match.size < 2

    metadata_url = "https://api.ncbi.nlm.nih.gov/lit/oai/books/?verb=GetRecord&identifier=oai:books.ncbi.nlm.nih.gov:#{book_id_match[1]}&metadataPrefix=nbk_meta"

    response = get_url(metadata_url)
    if response.status != 200
      error_msg = "Page retrieval (#{metadata_url} for NIH Bookshelf #{url}) failed with status #{response.status}"
      Rails.logger.warn error_msg
      return { error: error_msg }
    end

    metadata_xml = Nokogiri::XML(response.body)
    # Data is present in multiple namespaces, but the data we retrieve is pretty specific so we can just ignore them
    metadata_xml.remove_namespaces!

    metadata = {}

    # Use the first paragraph of the abstract as the artifact description
    description = metadata_xml.at_xpath('//abstract//p[1]')&.content.presence&.squish
    metadata[:description] = description if description.present?
    date_str = metadata_xml.at_xpath('/OAI-PMH/GetRecord/record/header/datestamp')&.content.presence&.strip
    if date_str.present?
      metadata[:published_on] = parse_by_core_format(date_str)
      metadata[:published_on_precision] = DateTimePrecision.precision(date_str.split(/[-, :T]/).map(&:to_i))
    end

    metadata
  end

  module_function :parse_and_precision
end
