# frozen_string_literal: true

# Functionality for importing data from the EHC repository
class EhcImporter < CedarImporter
  repository_name 'EHC'
  repository_home_page Rails.configuration.ehc_home_page

  def self.download_and_update!
    # Retrieve all the artifacts
    response = Faraday.get(Rails.configuration.ehc_feed_url)
    raise "EHC retrieval failed with status #{response.status}" unless response.status == 200

    # Process each artifact
    response_xml = Nokogiri::XML(response.body)
    response_xml.xpath('/nodes/node').each do |artifact|
      artifact_uri = URI.parse(artifact.at_xpath('Link').content)
      artifact_path = artifact_uri.path
      cedar_id = "EHC-#{Digest::MD5.hexdigest(artifact_uri.to_s)}"
      doi = Regexp.last_match(1) if artifact.at_xpath('Citation').content =~ %r{(10.\d{4,9}/[-._;()/:A-Z0-9]+)}

      # Store artifact metadata
      update_or_create_artifact!(
        cedar_id,
        remote_identifier: artifact_path.to_s,
        title: artifact.at_xpath('Title').content.presence,
        description: artifact.at_xpath('Description').content.presence,
        url: artifact_uri.to_s,
        published_on: artifact.at_xpath('Publish-Date').content.presence,
        artifact_status: to_artifact_status(artifact.at_xpath('Status').content),
        artifact_type: artifact.at_xpath('Product-Type').content.presence,
        keywords: extract_keywords(artifact),
        doi: doi
      )
    end
  end

  def self.extract_keywords(artifact)
    topics = artifact.at_xpath('Health-Topics').content&.split('|')&.collect { |item| item.strip } || []
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
      'retired'
    else
      'active'
    end
  end
end
