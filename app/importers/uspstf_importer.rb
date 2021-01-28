# frozen_string_literal: true

# Functionality for importing data from the USPSTF repository
class UspstfImporter
  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_base_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
    importer.remove_obsolete_entries!
  end

  def initialize(uspstf_json)
    @json_data = JSON.parse(uspstf_json)
    @found_ids = []
  end

  def update_db!
    uspstf = Repository.where(name: 'USPSTF').first_or_create!(home_page: Rails.configuration.uspstf_home_page)
    general_rec_urls = {}
    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      keywords = recommendation['keywords']&.split('|') || []
      cedar_id = "USPSTF-GR-#{id}"
      @found_ids << cedar_id
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      artifact_url = "#{Rails.configuration.uspstf_home_page}recommendation/#{recommendation['uspstfAlias']}"
      Artifact.update_or_create!(
        cedar_id,
        remote_identifier: id.to_s,
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['clinical']).squish,
        url: artifact_url,
        published_on: Date.new(recommendation['topicYear'].to_i),
        artifact_type: 'General Recommendation',
        artifact_status: 'active',
        keywords: keywords
      )
      general_rec_urls[id] = artifact_url
    end

    # Extract specific recommendations
    # TODO: consider whether specific recommendations should be standalone entries; alternately, we may wish
    # to only have entries for the specific recommendations because of the metadata
    @json_data['specificRecommendations'].each do |recommendation|
      cedar_id = "USPSTF-SR-#{recommendation['id']}"
      @found_ids << cedar_id
      # TODO: publish date and url are not explicit fields in the JSON
      Artifact.update_or_create!(
        cedar_id,
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['text']).squish,
        url: general_rec_urls[recommendation['general'].to_s],
        artifact_type: 'Specific Recommendation',
        artifact_status: 'active'
      )
    end

    # Extract tools
    @json_data['tools'].each_pair do |id, tool|
      cedar_id = "USPSTF-TOOL-#{id}"
      @found_ids << cedar_id
      Artifact.update_or_create!(
        cedar_id,
        title: tool['title'],
        repository: uspstf,
        url: tool['url'],
        artifact_type: 'Tool',
        artifact_status: 'active'
      )
    end
  end

  # Remove any USPSTF entries that were not found in the completed index run
  def remove_obsolete_entries!
    Artifact.where(repository: @ehc_repository).where.not(cedar_identifier: @found_ids).destroy_all
  end
end
