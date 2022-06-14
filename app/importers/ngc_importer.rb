# frozen_string_literal: true

# Functionality for importing data from the NGC repository
class NgcImporter < CedarImporter
  repository_name 'National Guideline Clearinghouse'
  repository_alias 'NGC'
  repository_home_page Rails.configuration.ngc_base_url

  extend PageScraper

  CACHE_DIR = File.join('tmp', 'cache', 'ngc')

  def self.download_and_update!
    update_cache!
    index_cached_files!
  end

  def self.update_cache!
    Dir.mkdir(CACHE_DIR) unless Dir.exist?(CACHE_DIR)
    index_file = File.join(CACHE_DIR, 'index.json')
    index = File.exist?(index_file) ? JSON.parse(File.read(index_file)) : {}

    if index.empty?
      index = scrape_ngc_index
      File.write(index_file, JSON.pretty_generate(index))
    end

    fetch_missing_files(index)
  end

  def self.index_cached_files!
    index_file = File.join(CACHE_DIR, 'index.json')
    raise "NGC cache not found: #{index_file}" unless File.exist?(index_file)

    index = JSON.parse(File.read(index_file))
    index.each_pair do |artifact_id, cached_data|
      metadata = {}
      warnings = []
      artifact_url = "#{Rails.configuration.ngc_base_url}#{cached_data['html_path']}"
      xml_file = File.join(CACHE_DIR, "#{artifact_id}.xml")
      if File.exist?(xml_file)
        xml_dom = Nokogiri::XML(File.read(xml_file))

        # NGC artifact dates have the following format: 2005 Aug (reaffirmed 2013)
        # Remove the parentheses and any text between them -- otherwise, the date has greater precision than it should
        date_string = xml_dom.at_xpath('//Field[@FieldID="128"]/FieldValue/@Value').value.sub(/\s*\(.+\)$/, '')
        warning_context = "Encountered #{@repository_alias} search entry '#{cached_data['title']}' with invalid date"
        published_date, warnings, published_on_precision = PageScraper.parse_and_precision(date_string, warning_context, warnings)
        artifact_description_html = xml_dom.at_xpath('//Field[@FieldID="151"]/FieldValue/@Value').value
        metadata.merge!(
          remote_identifier: artifact_id,
          title: cached_data['title'],
          description_html: artifact_description_html,
          url: artifact_url,
          published_on: published_date,
          published_on_precision: published_on_precision,
          artifact_type: 'Guideline',
          artifact_status: 'active',
          keywords: [],
          warnings: []
        )
      else
        metadata[:error] = "Failed to retrieve #{artifact_id}.xml"
      end
      html_file = File.join(CACHE_DIR, "#{artifact_id}.html")
      if File.exist?(html_file)
        html = File.read(html_file)
        metadata.merge!(extract_html_metadata(html, html_file))
        metadata.merge!(keywords: extract_keywords(html))
      else
        metadata[:error] = "Failed to retrieve #{artifact_id}.html"
      end
      metadata[:warnings].concat warnings
      cedar_id = "NGC-#{Digest::MD5.hexdigest(artifact_url)}"
      update_or_create_artifact!(cedar_id, metadata)
      Rails.logger.info "Processed NGC artifact #{artifact_url}"
    end
  end

  def self.extract_keywords(html_text)
    keywords = []
    html = Nokogiri::HTML(html_text)
    html.css('div#classification-tab div.field').each do |field|
      title = field.at_css('h5.field-label').content
      # TODO: use keyword metadata to identify UMLS CUI as well
      case title
      when 'MSH'
        field.css('div.field-content a').each do |mesh_keyword|
          keywords << mesh_keyword.content
        end
      when 'MTH'
        field.css('div.field-content a').each do |keyword|
          keywords << keyword.content
        end
      end
    end

    keywords
  end

  def self.fetch_missing_files(index)
    index.each_pair do |artifact_id, metadata|
      fetch_file_if_missing(metadata['html_path'], File.join(CACHE_DIR, "#{artifact_id}.html"))
      fetch_file_if_missing(metadata['xml_path'], File.join(CACHE_DIR, "#{artifact_id}.xml"))
    end
  end

  def self.fetch_file_if_missing(url_path, file)
    return if File.exist? file

    connection = Faraday.new(
      url: Rails.configuration.ngc_base_url,
      ssl: { verify: false }
    )
    response = connection.get(url_path)
    if response.status != 200
      Rails.logger.warn "#{@repository_alias} retrieval failed with status #{response.status}: #{Rails.configuration.ngc_base_url}#{url_path}"
      return
    end

    File.write(file, response.body.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
  end

  def self.scrape_ngc_index
    index = {}
    connection = Faraday.new Rails.configuration.ngc_base_url, ssl: { verify: false }
    response = connection.get '/search?q=&pageSize=10000&page=1'
    raise "#{@repository_alias} index retrieval failed with status #{response.status}" unless response.status == 200

    html = Nokogiri::HTML(response.body)
    html.css('div.results-list div.results-list-item').each do |artifact|
      meta_node = artifact.at_css('ul.item-meta')
      artifact_id = meta_node.content.match(/NGC:(\d+)/)&.send(:[], 1)
      next if artifact_id.blank?

      artifact_xml_path = "/summaries/downloadcontent/ngc-#{artifact_id.to_i}?contentType=xml"
      artifact_title = artifact.at_css('h3.results-list-item-title').content.strip
      artifact_html_path = artifact.at_css('h3.results-list-item-title a')['href'].strip
      index[artifact_id] = {
        'title' => artifact_title,
        'xml_path' => artifact_xml_path,
        'html_path' => artifact_html_path
      }
    end

    index
  end
end
