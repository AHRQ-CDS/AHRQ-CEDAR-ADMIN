# frozen_string_literal: true

# Functionality for importing data from the EHC repository
class EhcImporter
  def self.download_and_update!
    # Retrieve all the artifacts
    response = Faraday.get(Rails.configuration.ehc_feed_url)
    raise "EHC retrieval failed with status #{response.status}" unless response.status == 200

    ehc_repository = Repository.where(name: 'EHC').first_or_create!(home_page: Rails.configuration.ehc_home_page)

    # Process each artifact
    response_xml = Nokogiri::XML(response.body)
    response_xml.xpath('/nodes/node').each do |artifact|
      artifact_uri = URI.parse(artifact.at_xpath('Link').content)
      artifact_path = artifact_uri.path
      cedar_id = ['EHC', artifact_path.split('/').reject(&:empty?)].flatten.join('-')
      doi = Regexp.last_match(1) if artifact.at_xpath('Citation').content =~ %r{(10.\d{4,9}/[-._;()/:A-Z0-9]+)}

      # Store artifact metadata
      Artifact.update_or_create!(
        cedar_id,
        remote_identifier: artifact_path.to_s,
        repository: ehc_repository,
        title: artifact.at_xpath('Title').content.presence,
        description: artifact.at_xpath('Description').content.presence,
        url: artifact_uri.to_s,
        published_on: artifact.at_xpath('Publish-Date').content.presence,
        artifact_status: to_artifact_status(artifact.at_xpath('Status').content),
        artifact_type: artifact.at_xpath('Product-Type').content.presence,
        mesh_keywords: artifact.at_xpath('Health-Topics').content&.split('|')&.collect { |item| item.strip },
        keywords: artifact.at_xpath('Keywords').content&.split(',')&.collect { |item| item.strip },
        doi: doi
      )
    end
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
