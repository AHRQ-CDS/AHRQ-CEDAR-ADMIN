# frozen_string_literal: true

require 'json'
require 'net/http'
require './app/models/repository'
require './app/models/artifact'
require './app/models/artifact_type'
require './app/models/artifact_type_association'

module Importers
  # Functionality for importing data from the USPSTF repository
  class UspstfRepositoryImporter
    def self.download_and_update!
      uri = URI(Rails.configuration.uspstf_url)
      json = Net::HTTP.get(uri)
      importer = UspstfRepositoryImporter.new(json)
      importer.update_db!
    end

    def initialize(uspstf_json)
      @json_data = JSON.parse(uspstf_json)
    end

    def update_db!
      uspstf = Repository.uspstf!
      recommendation_type = ArtifactType.recommendation!

      # Extract specific recommendations
      @json_data['specificRecommendations'].each do |recommendation|
        artifact = Artifact.find_or_initialize_by(
          remote_identifier: "#{Repository::USPSTF}_SR_#{recommendation['id']}"
        )
        # TODO: publish date and url are not explicit fields in the JSON
        artifact.update!(
          title: recommendation['title'],
          repository: uspstf,
          description: ActionView::Base.full_sanitizer.sanitize(recommendation['text'])
        )
        association = ArtifactTypeAssociation.find_or_initialize_by(
          artifact: artifact,
          artifact_type: recommendation_type
        )
        association.save!
      end

      # Extract general recommendations
      @json_data['generalRecommendations'].each_pair do |id, recommendation|
        artifact = Artifact.find_or_initialize_by(
          remote_identifier: "#{Repository::USPSTF}_GR_#{id}"
        )
        # TODO: clinicalUrl and otherUrl fields in JSON are not always resolvable
        artifact.update!(
          title: recommendation['title'],
          repository: uspstf,
          description: ActionView::Base.full_sanitizer.sanitize(recommendation['clinical']),
          url: recommendation['clinicalUrl'],
          published: Date.new(recommendation['topicYear'].to_i)
        )
        association = ArtifactTypeAssociation.find_or_initialize_by(
          artifact: artifact,
          artifact_type: recommendation_type
        )
        association.save!
      end

      # Extract tools
      tool_type = ArtifactType.tool!
      @json_data['tools'].each_pair do |id, tool|
        artifact = Artifact.find_or_initialize_by(
          remote_identifier: "#{Repository::USPSTF}_TOOL_#{id}"
        )
        artifact.update!(
          title: tool['title'],
          repository: uspstf,
          url: tool['url']
        )
        association = ArtifactTypeAssociation.find_or_initialize_by(
          artifact: artifact,
          artifact_type: tool_type
        )
        association.save!
      end
    end
  end
end
