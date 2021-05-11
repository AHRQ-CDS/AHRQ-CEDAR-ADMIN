# frozen_string_literal: true

# Functionality for importing data from the CDS Connect repository
class CdsConnectImporter < CedarImporter
  repository_name 'CDS Connect'
  repository_fhir_id 'cds-connect'
  repository_home_page Rails.configuration.cds_connect_home_page

  def self.download_and_update!
    # Set up our connection object to manage cookies and basic auth if needed
    connection = Faraday.new(url: Rails.configuration.cds_connect_base_url) do |builder|
      builder.use :cookie_jar
      # NOTE: Basic auth is only needed for the staging server
      if Rails.configuration.cds_connect_basic_auth_username && Rails.configuration.cds_connect_basic_auth_password
        builder.basic_auth(Rails.configuration.cds_connect_basic_auth_username, Rails.configuration.cds_connect_basic_auth_password)
      end
    end

    # Send our login request
    credentials = {
      name: Rails.configuration.cds_connect_username,
      pass: Rails.configuration.cds_connect_password
    }
    response = connection.post('user/login?_format=json', credentials.to_json, 'Content-Type' => 'application/json')
    raise "CDS Connect login failed with status #{response.status}" unless response.status == 200

    # Retrieve all the artifact IDs
    response = connection.get('rest/views/artifacts?_format=json')
    raise "CDS Connect ID retrieval failed with status #{response.status}" unless response.status == 200

    # Pull out the list of IDs
    artifact_list = JSON.parse(response.body)
    artifact_ids = artifact_list.map { |a| a['nid'] }

    # Retrieve and process each artifact based on the ID
    artifact_ids.each do |artifact_id|
      response = connection.get("cds_api/#{artifact_id}")
      # TODO: More robustness against failure of a single artifact retrieval
      raise "CDS Connect artifact retrieval failed with status #{response.status}" unless response.status == 200

      # Store artifact metadata
      artifact = JSON.parse(response.body)
      cds_connect_status = artifact['status'].downcase
      update_or_create_artifact!(
        "CDS-CONNECT-#{artifact_id}",
        remote_identifier: artifact_id.to_s,
        title: artifact['title'],
        description_html: artifact['description'],
        url: "#{Rails.configuration.cds_connect_base_url}node/#{artifact_id}",
        published_on: artifact['repository_information']['publication_date'],
        artifact_type: artifact['artifact_type'],
        artifact_status: Artifact.artifact_statuses[cds_connect_status] || 'unknown',
        keywords: artifact['creation_and_usage']['keywords'] || [],
        mesh_keywords: artifact['organization']['mesh_topics'] || []
      )
    end

    # Logout
    connection.post('user/logout')
  end
end
