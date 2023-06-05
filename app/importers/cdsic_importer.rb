# frozen_string_literal: true

# Functionality for importing data from the CDSiC repository
class CdsicImporter < CedarImporter
  repository_name 'Clinical Decision Support Innovation Collaborative'
  repository_alias 'CDSiC'
  # NOTE: holding off using configuration for home page until CDSiC import uses a more standard model
  repository_home_page 'https://cdsic.ahrq.gov/cdsic/home-page'

  extend PageScraper

  # There is currently a single CDSiC artifact and there is not yet an index of artifacts, so we start by
  # creating a local list of known artifacts until that index is available
  ARTIFACT_URLS = [
    {
      page: 'https://cdsic.ahrq.gov/cdsic/srf-environmental-scan-report',
      pdf: 'https://cdsic.ahrq.gov/sites/default/files/2023-05/FINALSRFLevel1EnvironmentalScan1.pdf'
    }
  ].freeze

  def self.download_and_update!
    ARTIFACT_URLS.each_with_index do |artifact_url, idx|
      cedar_id = "CDSiC-#{Digest::MD5.hexdigest(idx.to_s)}"
      page_metadata = extract_metadata(artifact_url[:page])
      pdf_metadata = extract_metadata(artifact_url[:pdf])
      metadata = {
        remote_identifier: artifact_url[:pdf],
        title: page_metadata[:title] || pdf_metadata[:title],
        description: page_metadata[:description] || pdf_metadata[:description],
        url: artifact_url[:pdf],
        published_on: page_metadata[:published_on] || pdf_metadata[:published_on],
        published_on_precision: [page_metadata[:published_on_precision].to_i, pdf_metadata[:published_on_precision].to_i].max,
        artifact_type: 'Environmental Scan',
        artifact_status: page_metadata[:status] || pdf_metadata[:status] || 'active',
        keywords: page_metadata[:keywords].to_a | pdf_metadata[:keywords].to_a,
        doi: page_metadata[:doi] || pdf_metadata[:doi],
        error: page_metadata[:error] || pdf_metadata[:error]
      }
      metadata.delete_if { |_k, v| v.nil? }
      update_or_create_artifact!(cedar_id, metadata)
    end
  end
end
