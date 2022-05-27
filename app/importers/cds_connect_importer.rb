# frozen_string_literal: true

# Functionality for importing data from the CDS Connect repository
class CdsConnectImporter < CedarImporter
  repository_name 'CDS Connect'
  repository_alias 'CDS Connect'
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

    # Retrieve all the artifact IDs before we login (this ensures only the latest artifacts are listed and avoids duplicates)
    response = connection.get('rest/views/artifacts?_format=json')
    raise "CDS Connect ID retrieval failed with status #{response.status}" unless response.status == 200

    artifact_list = JSON.parse(response.body)
    artifact_ids = artifact_list.map { |a| a['nid'] }

    # Send our login request so we can access each artifact via the API
    credentials = {
      name: Rails.configuration.cds_connect_username,
      pass: Rails.configuration.cds_connect_password
    }
    response = connection.post('user/login?_format=json', credentials.to_json, 'Content-Type' => 'application/json')
    raise "CDS Connect login failed with status #{response.status}" unless response.status == 200

    # Retrieve and process each artifact based on the ID
    artifact_ids.each do |artifact_id|
      attributes = {}
      artifact_path = "cds_api/#{artifact_id}"
      try do
        response = connection.get(artifact_path)
        if response.status == 200
          # Extract artifact metadata
          artifact = JSON.parse(response.body)
          cds_connect_status = artifact['status'].downcase
          cds_connect_status = 'archived' if cds_connect_status == 'retired'
          keywords = artifact['creation_and_usage']['keywords'] || []
          keywords.concat(artifact['organization']['mesh_topics'] || [])
          recommendation_statements = artifact.dig('supporting_evidence', 'recommendation_statement')
          if recommendation_statements.present?
            strength = ActionView::Base.full_sanitizer.sanitize(
              recommendation_statements[0]['strength_of_recommendation']
            )&.gsub(/\s+/, ' ')
            quality = ActionView::Base.full_sanitizer.sanitize(
              recommendation_statements[0]['quality_of_evidence']
            )&.gsub(/\s+/, ' ')
          end
          warning_context = "Encountered CDS Connect entry '#{artifact['title']}' with invalid date"
          published_date = parse_date_string(artifact['repository_information']['publication_date'], warning_context)

          attributes.merge!(
            remote_identifier: artifact_id.to_s,
            title: artifact['title'],
            description_html: artifact['description'],
            url: "#{Rails.configuration.cds_connect_base_url}node/#{artifact_id}",
            published_on: published_date,
            published_on_precision: published_date.precision,
            artifact_type: artifact['artifact_type']&.strip.presence,
            artifact_status: Artifact.artifact_statuses[cds_connect_status] || 'unknown',
            keywords: keywords,
            strength_of_recommendation_statement: strength,
            quality_of_evidence_statement: quality
          )
        else
          error_msg = "CDS Connect artifact retrieval failed for #{artifact_path} with status #{response.status}"
          Rails.logger.warn error_msg
          attributes[:error] = error_msg
        end
      rescue Faraday::ConnectionFailed => e
        error_msg = "CDS Connect artifact retrieval failed for #{artifact_path}: #{e.message}"
        Rails.logger.warn error_msg
        attributes[:error] = error_msg
      end
      update_or_create_artifact!("CDS-CONNECT-#{artifact_id}", attributes)
    end

    # Logout
    connection.post('user/logout')
  end
end
