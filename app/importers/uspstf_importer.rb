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
    recommendation_type = ArtifactType.recommendation!

    # Extract specific recommendations
    @json_data['specificRecommendations'].each do |recommendation|
      # TODO: publish date and url are not explicit fields in the JSON
      Artifact.update_or_create!(
        "USPSTF_SR_#{recommendation['id']}",
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['text']),
        artifact_types: [recommendation_type]
      )
    end

    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      # TODO: clinicalUrl and otherUrl fields in JSON are not resolvable
      Artifact.update_or_create!(
        "USPSTF_GR_#{id}",
        title: recommendation['title'],
        repository: uspstf,
        description: ActionView::Base.full_sanitizer.sanitize(recommendation['clinical']),
        url: "https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/#{recommendation['uspstfAlias']}",
        published: Date.new(recommendation['topicYear'].to_i),
        artifact_types: [recommendation_type]
      )
    end

    # Extract tools
    tool_type = ArtifactType.tool!
    @json_data['tools'].each_pair do |id, tool|
      Artifact.update_or_create!(
        "USPSTF_TOOL_#{id}",
        title: tool['title'],
        repository: uspstf,
        url: tool['url'],
        artifact_types: [tool_type]
      )
    end
  end
end
