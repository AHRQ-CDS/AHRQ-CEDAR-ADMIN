# frozen_string_literal: true

# Functionality for importing data from the USPSTF repository
class UspstfImporter < CedarImporter
  repository_name 'USPSTF'
  repository_fhir_id 'uspstf'
  repository_home_page Rails.configuration.uspstf_home_page

  include PageScraper

  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_base_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
    importer.remove_obsolete_entries!
  end

  def initialize(uspstf_json)
    super()
    @json_data = JSON.parse(uspstf_json)
    @found_ids = {}
  end

  def update_db!
    general_rec_urls = {}
    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      keywords = recommendation['keywords']&.split('|') || []
      cedar_id = "USPSTF-GR-#{id}"
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      url = "#{Rails.configuration.uspstf_home_page}recommendation/#{recommendation['uspstfAlias']}"
      @found_ids[cedar_id] = url
      mesh_keywords = []

      recommendation['categories'].each do |cat|
        mesh_keywords << @json_data['categories'][cat.to_s]['name']
      end

      update_or_create_artifact!(
        cedar_id,
        remote_identifier: id.to_s,
        title: recommendation['title'],
        description_html: recommendation['clinical'],
        url: url,
        published_on: Date.new(recommendation['topicYear'].to_i),
        artifact_type: 'General Recommendation',
        artifact_status: 'active',
        keywords: keywords,
        mesh_keywords: mesh_keywords
      )
      general_rec_urls[id] = url
    end

    # Extract specific recommendations
    # TODO: consider whether specific recommendations should be standalone entries; alternately, we may wish
    # to only have entries for the specific recommendations because of the metadata
    @json_data['specificRecommendations'].each do |recommendation|
      cedar_id = "USPSTF-SR-#{recommendation['id']}"
      url = general_rec_urls[recommendation['general'].to_s]
      @found_ids[cedar_id] = url

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
      @found_ids[cedar_id] = url
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

  # Remove any USPSTF entries that were not found in the completed index run
  # USPSTF JSON identifiers are not persistent so this step is needed to clean up the
  # database
  # TODO: Just mark these as deleted? By adding an artifact status?
  # TODO: Move this to the base class and do it automatically for all importers (with stats kept)
  def remove_obsolete_entries!
    repository.artifacts.where.not(cedar_identifier: @found_ids.keys).destroy_all
  end
end
