# frozen_string_literal: true

# Functionality for importing data from the SRDR repository
class SrdrImporter < CedarImporter
  repository_name 'Systematic Review Data Repository'
  repository_alias 'SRDR'
  repository_home_page Rails.configuration.srdr_base_url

  def self.download_and_update!
    # Set up our connection object with our API key
    connection = Faraday.new(url: Rails.configuration.srdr_base_url, params: { api_key: Rails.configuration.srdr_api_key })

    # Retrieve all the artifacts
    response = connection.get('/api/v2/public_projects.json')
    raise "SRDR Plus ID retrieval failed with status #{response.status}" unless response.status == 200

    # Process each artifact
    response_json = JSON.parse(response.body)
    artifacts = response_json['projects']
    artifacts.each do |artifact|
      # Store artifact metadata
      # TODO: Artifact contains the URL for the API entry point for the artifact; look into 1) whether this
      # has additional data and, if so, 2) updating SRDR to allow read access to anyone with an API key
      keywords = artifact['mesh_descriptors']&.collect { |descriptor| descriptor['name'] }
      status = if artifact['deleted_at'].present?
                 'archived'
               elsif artifact['published_at'].blank?
                 'draft'
               else
                 'active'
               end
      update_or_create_artifact!(
        "SRDR-PLUS-#{artifact['id']}",
        remote_identifier: artifact['id'].to_s,
        title: artifact['name'],
        description_html: artifact['description'],
        url: "#{Rails.configuration.srdr_base_url}public_data?id=#{artifact['id']}&type=project",
        doi: artifact['doi'],
        published_on: artifact['published_at'],
        keywords: keywords,
        artifact_status: status,
        artifact_type: 'Systematic Review'
      )
    end
  end
end
