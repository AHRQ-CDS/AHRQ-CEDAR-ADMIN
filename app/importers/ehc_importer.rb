# frozen_string_literal: true

# Functionality for importing data from the EHC repository
class EhcImporter < CedarImporter
  repository_name 'Effective Health Care Program'
  repository_alias 'EHC'
  repository_home_page Rails.configuration.ehc_home_page
  repository_description 'The AHRQ EHC Program\'s goal is to improve healthcare quality by enabling ' \
                         'access to the best available evidence on outcomes and appropriateness ' \
                         'of healthcare treatments, devices, and services.'

  def self.download_and_update!
    # Retrieve all the artifacts
    response = Faraday.get(Rails.configuration.ehc_feed_url)
    raise "EHC retrieval failed with status #{response.status}" unless response.status == 200

    # Process each artifact
    response_xml = Nokogiri::XML(response.body)
    response_xml.xpath('/response/item').each do |artifact|
      artifact_uri = URI.parse(artifact.at_xpath('Link').content.strip)
      cedar_id = "EHC-#{Digest::MD5.hexdigest(artifact_uri.to_s)}"
      doi = Regexp.last_match(1) if artifact.at_xpath('Citation').content =~ %r{(10.\d{4,9}/[-._;()/:A-Z0-9]+)}
      # The EHC XML feed wraps titles, descriptions and keywords with a CDATA section that
      # prevents automatic unescaping of character entities in the text so we do that manually
      artifact_title = CGI.unescapeHTML(artifact.at_xpath('Title').content).presence
      warning_context = "Encountered #{@repository_alias} search entry '#{artifact_title}' with invalid date"
      published_date, warnings, published_on_precision = PageScraper.parse_and_precision(
        artifact.at_xpath('Publish-Date').content.presence, warning_context, []
      )
      warnings << ("Missing URL for #{cedar_id} (#{artifact_title})") if artifact_uri.to_s.empty?
      # Store artifact metadata
      update_or_create_artifact!(
        cedar_id,
        remote_identifier: artifact_uri.to_s.presence,
        title: artifact_title,
        description: CGI.unescapeHTML(artifact.at_xpath('Description').content).presence,
        url: artifact_uri.to_s.presence,
        published_on: published_date,
        published_on_precision: published_on_precision,
        artifact_status: to_artifact_status(artifact.at_xpath('Status').content),
        artifact_type: artifact.at_xpath('Product-Type')&.content&.strip.presence,
        keywords: extract_keywords(artifact),
        doi: doi,
        warnings: warnings
      )
    end
  end

  def self.extract_keywords(artifact)
    # Keywords are typically separated using commas, but sometimes HTML linefeeds show up
    topics = artifact.at_xpath('Health-Topics').content&.split(%r{,|<br\s*/>\s*})&.collect(&:strip) || []
    keywords = artifact.at_xpath('Keywords').content&.split(%r{,|<br\s*/>\s*})&.collect(&:strip) || []
    topics.concat(keywords).select(&:present?).map { |keyword| CGI.unescapeHTML(keyword) }
  end

  def self.to_artifact_status(status)
    case status
    when nil
      'unknown'
    when 'Draft'
      'draft'
    when 'Archived'
      'archived'
    else
      'active'
    end
  end
end
