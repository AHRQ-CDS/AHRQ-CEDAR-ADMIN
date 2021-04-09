# frozen_string_literal: true

# Functionality for importing data from the NGC repository
class NgcImporter
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
