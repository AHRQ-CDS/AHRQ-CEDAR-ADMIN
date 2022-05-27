# frozen_string_literal: true

# Functionality for importing data from the EHC repository
class EhcImporter < CedarImporter
  extend Utilities
  repository_name 'Effective Health Care Program'
  repository_alias 'EHC'
  repository_home_page Rails.configuration.ehc_home_page

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
      artifact_title = artifact.at_xpath('Title').content.presence
      warnings = ["Missing URL for #{cedar_id} (#{artifact_title})"] if artifact_uri.to_s.empty?
      error_context = "Encountered EHC entry '#{artifact_title}' with invalid date"
      published_date = parse_date_string(artifact.at_xpath('Publish-Date').content.presence, error_context)

      # Store artifact metadata
      update_or_create_artifact!(
        cedar_id,
        remote_identifier: artifact_uri.to_s.presence,
        title: artifact_title,
        description: artifact.at_xpath('Description').content.presence,
        url: artifact_uri.to_s.presence,
        published_on: published_date,
        published_on_precision: published_date.precision,
        artifact_status: to_artifact_status(artifact.at_xpath('Status').content),
        artifact_type: artifact.at_xpath('Product-Type')&.content&.strip.presence,
        keywords: extract_keywords(artifact),
        doi: doi,
        warnings: warnings
      )
    end
  end

  def self.extract_keywords(artifact)
    topics = artifact.at_xpath('Health-Topics').content&.split(',')&.collect { |item| item.strip } || []
    keywords = artifact.at_xpath('Keywords').content&.split(',')&.collect { |item| item.strip } || []
    topics.concat(keywords)
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
