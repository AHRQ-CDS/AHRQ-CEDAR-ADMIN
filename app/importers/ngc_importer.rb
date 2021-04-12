# frozen_string_literal: true

# Functionality for importing data from the NGC repository
class NgcImporter
  extend PageScraper
  CACHE_DIR = File.join('tmp', 'cache', 'ngc')

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
    ngc_repository = Repository.where(name: 'NGC').first_or_create!(home_page: Rails.configuration.ngc_base_url)
    index_file = File.join(CACHE_DIR, 'index.json')
    raise "NGC cache not found: #{index_file}" unless File.exist?(index_file)

    index = JSON.parse(File.read(index_file))
    index.each_pair do |artifact_id, cached_data|
      xml_file = File.join(CACHE_DIR, "#{artifact_id}.xml")
      if File.exist?(xml_file)
        xml_dom = Nokogiri::XML(File.read(xml_file))
        begin
          artifact_date_str = xml_dom.at_xpath('//Field[@FieldID="128"]/FieldValue/@Value').value
          artifact_date = Date.parse(artifact_date_str)
        rescue Date::Error
          Rails.logger.warn "Unable to parse date (#{artifact_date_str}) for NGC artifact #{artifact_id}"
        end
        artifact_description_html = xml_dom.at_xpath('//Field[@FieldID="151"]/FieldValue/@Value').value
      end
      artifact_url = "#{Rails.configuration.ngc_base_url}#{cached_data['html_path']}"
      metadata = {
        remote_identifier: artifact_id,
        repository: ngc_repository,
        title: cached_data['title'],
        description_html: artifact_description_html,
        url: artifact_url,
        published_on: artifact_date,
        artifact_type: 'Guideline',
        artifact_status: 'active',
        keywords: [],
        mesh_keywords: []
      }
      html_file = File.join(CACHE_DIR, "#{artifact_id}.html")
      if File.exist?(html_file)
        html = File.read(html_file)
        metadata.merge!(extract_html_metadata(html))
        metadata.merge!(extract_keywords(html))
      end
      cedar_id = "NGC-#{URI.parse(artifact_url).select(:host, :path, :fragment, :query).join('-').scan(/\w+/).join('-')}"
      Artifact.update_or_create!(cedar_id, metadata)
      Rails.logger.info "Processed NGC artifact #{artifact_url}"
    end
  end

  def self.extract_keywords(html_text)
    all_keywords = {}
    html = Nokogiri::HTML(html_text)
    html.css('div#classification-tab div.field').each do |field|
      title = field.at_css('h5.field-label').content
      case title
      when 'MSH'
        all_keywords[:mesh_keywords] = []
        field.css('div.field-content a').each do |mesh_keyword|
          all_keywords[:mesh_keywords] << mesh_keyword.content
        end
      when 'MTH'
        all_keywords[:keywords] = []
        field.css('div.field-content a').each do |keyword|
          all_keywords[:keywords] << keyword.content
        end
      end
    end
    all_keywords
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
      Rails.logger.warn "NGC retrieval failed with status #{response.status}: #{Rails.configuration.ngc_base_url}#{url_path}"
      return
    end

    File.write(file, response.body.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
  end

  def self.scrape_ngc_index
    index = {}
    connection = Faraday.new Rails.configuration.ngc_base_url, ssl: { verify: false }
    response = connection.get '/search?q=&pageSize=10000&page=1'
    raise "NGC index retrieval failed with status #{response.status}" unless response.status == 200

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
