require 'json'
require './app/models/repository'
require './app/models/artifact'
require './app/models/artifact_type'
require './app/models/artifact_type_association'

module Importers

  # Functionality for importing data from the USPSTF repository
  class UspstfRepositoryImporter
    def initialize(uspstf_json)
      @json_data = JSON.parse(uspstf_json)
    end
    
    def update_db
      uspstf = Repository.uspstf!
      recommendation_type = ArtifactType.recommendation!
      @json_data['specificRecommendations'].each do |recommendation|
        artifact = Artifact.create(title: recommendation['title'], repository: uspstf, description: recommendation['text'], remote_identifier: recommendation['id'])
        ArtifactTypeAssociation.create(artifact: artifact, artifact_type: recommendation_type)
      end
    end
  end
  
end