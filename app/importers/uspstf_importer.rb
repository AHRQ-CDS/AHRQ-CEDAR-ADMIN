# frozen_string_literal: true

# Functionality for importing data from the USPSTF repository
class UspstfImporter < CedarImporter
  repository_name 'United States Preventive Services Taskforce'
  repository_alias 'USPSTF'
  repository_home_page Rails.configuration.uspstf_home_page

  include PageScraper

  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_base_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
  end

  def initialize(uspstf_json)
    super()
    @json_data = JSON.parse(uspstf_json)
  end

  def update_db!
    general_rec_urls = {}
    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      keywords = recommendation['keywords']&.split('|') || []
      recommendation['categories'].each do |cat|
        keywords << @json_data['categories'][cat.to_s]['name']
      end
      cedar_id = "USPSTF-GR-#{id}"
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      url = "#{Rails.configuration.uspstf_home_page}recommendation/#{recommendation['uspstfAlias']}"

      update_or_create_artifact!(
        cedar_id,
        remote_identifier: id.to_s,
        title: recommendation['title'],
        description_html: recommendation['clinical'],
        url: url,
        published_on: Date.new(recommendation['topicYear'].to_i),
        artifact_type: 'General Recommendation',
        artifact_status: 'active',
        keywords: keywords
      )
      general_rec_urls[id] = url
    end

    # Extract specific recommendations
    # TODO: consider whether specific recommendations should be standalone entries; alternately, we may wish
    # to only have entries for the specific recommendations because of the metadata
    @json_data['specificRecommendations'].each do |recommendation|
      cedar_id = "USPSTF-SR-#{recommendation['id']}"
      url = general_rec_urls[recommendation['general'].to_s]

      # TODO: publish date and url are not explicit fields in the JSON
      update_or_create_artifact!(
        cedar_id,
        remote_identifier: recommendation['id'].to_s,
        title: recommendation['title'],
        description_html: recommendation['text'],
        url: url,
        artifact_type: 'Specific Recommendation',
        artifact_status: 'active'
      )
    end

    # Extract tools
    @json_data['tools'].each_pair do |id, tool|
      cedar_id = "USPSTF-TOOL-#{id}"
      url = tool['url']
      metadata = {
        title: tool['title'],
        url: url,
        artifact_type: 'Tool',
        artifact_status: 'active'
      }
      metadata.merge!(extract_metadata(url))
      update_or_create_artifact!(cedar_id, metadata)
    end
  end
end
