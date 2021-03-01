# frozen_string_literal: true

# Functionality for importing data from the SRDR repository
class SrdrImporter
  def self.download_and_update!
    # Set up our connection object with our API key
    connection = Faraday.new(url: Rails.configuration.srdr_base_url, params: { api_key: Rails.configuration.srdr_api_key })

    # Retrieve all the artifacts
    response = connection.get('/api/v2/public_projects.json')
    raise "SRDR Plus ID retrieval failed with status #{response.status}" unless response.status == 200

    # Process each artifact
    response_json = JSON.parse(response.body)
    artifacts = response_json['projects']
    srdr_repository = Repository.where(name: 'SRDR').first_or_create!(home_page: Rails.configuration.srdr_base_url)
    artifacts.each do |artifact|
      # Store artifact metadata
      # TODO: Artifact contains the URL for the API entry point for the artifact; look into 1) whether this
      # has additional data and, if so, 2) updating SRDR to allow read access to anyone with an API key
      description = ActionView::Base.full_sanitizer.sanitize(artifact['description'])&.squish
      Artifact.update_or_create!(
        "SRDR-PLUS-#{artifact['id']}",
        remote_identifier: artifact['id'].to_s,
        repository: srdr_repository,
        title: artifact['name'],
        description: description,
        url: "#{Rails.configuration.srdr_base_url}projects/#{artifact['id']}",
        published_on: artifact['published_at'],
        artifact_status: 'unknown' # TODO: see if this can be determined in some way
        # TODO: see if there's a reasonable value for artifact_type
        # TODO: see if there are ways to determine keywords or mesh_keywords
      )
    end
  end
end
