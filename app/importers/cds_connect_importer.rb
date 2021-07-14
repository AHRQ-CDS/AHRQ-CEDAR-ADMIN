# frozen_string_literal: true

# Functionality for importing data from the CDS Connect repository
class CdsConnectImporter < CedarImporter
  repository_name 'CDS Connect'
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
    # The list we pull back can include many duplicate entries, presumably different versions of the same thing.
    # This list appears to be ordered most recent first so we can take the first unique entry and use the url
    # slug of the artifact to detect duplicates.
    # The url slugs include a trailing -nn or -nn-nn for each new version after the initial one, we match on the
    # URL slug minus the trailing numbers (if present).
    # Here's an example
    # {
    #   "field_version": "0.1.3",
    #   "uuid": "dd5e7f81-37bd-419a-a9a4-1e3f7427be57",
    #   "nid": "13416",
    #   "title": "<a href=\"/cdsconnect/artifact/aspirin-therapy-primary-prevention-cvd-and-colorectal-cancer-38\"
    #             hreflang=\"en\">Aspirin Therapy for Primary Prevention of CVD and Colorectal Cancer</a>"
    # }
    artifact_list = JSON.parse(response.body)
    artifact_ids = []
    slugs = {}
    artifact_list.each do |artifact|
      # Extract the full URL slug, e.g.:
      # /cdsconnect/artifact/aspirin-therapy-primary-prevention-cvd-and-colorectal-cancer-38
      slug = artifact['title'].match(%r{<a href="([/a-z0-9-]+)})[1]
      while slug.match(%r{([a-z0-9/-]+)-[0-9]+$})
        # Strip off a trailing -nn if present, may need to do this more than once if -nn-nn suffix
        # /cdsconnect/artifact/aspirin-therapy-primary-prevention-cvd-and-colorectal-cancer
        slug = slug.match(%r{([a-z0-9/-]+)-[0-9]+$})[1]
      end
      unless slugs.include? slug
        slugs[slug] = true
        artifact_ids << artifact['nid']
      end
    end

    # Retrieve and process each artifact based on the ID
    artifact_ids.each do |artifact_id|
      response = connection.get("cds_api/#{artifact_id}")
      attributes = {}
      if response.status == 200
        # Extract artifact metadata
        artifact = JSON.parse(response.body)
        cds_connect_status = artifact['status'].downcase
        keywords = artifact['creation_and_usage']['keywords'] || []
        keywords.concat(artifact['organization']['mesh_topics'] || [])
        attributes.merge!(
          remote_identifier: artifact_id.to_s,
          title: artifact['title'],
          description_html: artifact['description'],
          url: "#{Rails.configuration.cds_connect_base_url}node/#{artifact_id}",
          published_on: artifact['repository_information']['publication_date'],
          artifact_type: artifact['artifact_type'],
          artifact_status: Artifact.artifact_statuses[cds_connect_status] || 'unknown',
          keywords: keywords
        )
      else
        error_msg = "CDS Connect artifact retrieval failed with status #{response.status}"
        Rails.logger.warn error_msg
        attributes[:error] = error_msg
      end
      update_or_create_artifact!("CDS-CONNECT-#{artifact_id}", attributes)
    end

    # Logout
    connection.post('user/logout')
  end
end
