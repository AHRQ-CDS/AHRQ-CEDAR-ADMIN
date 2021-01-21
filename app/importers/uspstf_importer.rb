# frozen_string_literal: true

require 'json'
require 'net/http'

# Functionality for importing data from the USPSTF repository
class UspstfImporter
  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
  end

  def initialize(uspstf_json)
    @json_data = JSON.parse(uspstf_json)
  end

  def update_db!
    uspstf = Repository.where(name: 'USPSTF').first_or_create!
    general_rec_urls = {}

    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      artifact_url = "https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/#{recommendation['uspstfAlias']}"
      Artifact.update_or_create!(
        "USPSTF-GR-#{id}",
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['clinical']).squish,
        url: artifact_url,
        published: Date.new(recommendation['topicYear'].to_i),
        artifact_type: :general_recommendation
      )
      general_rec_urls[id] = artifact_url
    end

    # Extract specific recommendations
    @json_data['specificRecommendations'].each do |recommendation|
      # TODO: publish date and url are not explicit fields in the JSON
      Artifact.update_or_create!(
        "USPSTF-SR-#{recommendation['id']}",
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['text']).squish,
        url: general_rec_urls[recommendation['general'].to_s],
        artifact_type: :specific_recommendation
      )
    end

    # Extract tools
    @json_data['tools'].each_pair do |id, tool|
      Artifact.update_or_create!(
        "USPSTF-TOOL-#{id}",
        title: tool['title'],
        repository: uspstf,
        url: tool['url'],
        artifact_type: :tool
      )
    end
  end
end
