# frozen_string_literal: true

# Functionality for importing data from the USPSTF repository
class UspstfImporter
  include PageScraper

  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_base_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
    importer.remove_obsolete_entries!
  end

  def initialize(uspstf_json)
    @json_data = JSON.parse(uspstf_json)
    @found_ids = {}
  end

  def update_db!
    uspstf = Repository.where(name: 'USPSTF').first_or_create!(home_page: Rails.configuration.uspstf_home_page)
    general_rec_urls = {}
    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      keywords = recommendation['keywords']&.split('|') || []
      cedar_id = "USPSTF-GR-#{id}"
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      url = "#{Rails.configuration.uspstf_home_page}recommendation/#{recommendation['uspstfAlias']}"
      @found_ids[cedar_id] = url
      Artifact.update_or_create!(
        cedar_id,
        remote_identifier: id.to_s,
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['clinical']).squish,
        description_html: ActionView::Base.safe_list_sanitizer.sanitize(recommendation['clinical']).squish,
        description_markdown: ReverseMarkdown.convert(recommendation['clinical']),
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
      @found_ids[cedar_id] = url
      # TODO: publish date and url are not explicit fields in the JSON
      Artifact.update_or_create!(
        cedar_id,
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['text']).squish,
        description_html: ActionView::Base.safe_list_sanitizer.sanitize(recommendation['text']).squish,
        description_markdown: ReverseMarkdown.convert(recommendation['text']),
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
        repository: uspstf,
        url: url,
        artifact_type: 'Tool',
        artifact_status: 'active'
      }
      metadata.merge!(extract_metadata(url))
      Artifact.update_or_create!(cedar_id, metadata)
    end
  end

  # Remove any USPSTF entries that were not found in the completed index run
  # USPSTF JSON identifiers are not persistent so this step is needed to clean up the
  # database
  def remove_obsolete_entries!
    Artifact.where(repository: @ehc_repository).where.not(cedar_identifier: @found_ids.keys).destroy_all
  end
end
