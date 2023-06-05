# frozen_string_literal: true

class CdsicImporterTest < ActiveSupport::TestCase
  test 'import sample CDSiC content into the database' do
    # Sample data for mocking
    html = file_fixture('srf-environmental-scan-report.html')
    pdf = file_fixture('FINALSRFLevel1EnvironmentalScan1.pdf')

    # Stub out requests and return mock data
    stub_request(:get, /srf-environmental-scan-report/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: html)
    stub_request(:get, /pdf/).to_return(status: 200, headers: { 'Content-Type' => 'application/pdf' }, body: pdf)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'CDSiC').count)

    # Load the mock records
    CdsicImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'CDSiC').count)
    artifacts = Repository.where(alias: 'CDSiC').first.artifacts
    assert_equal(1, artifacts.count)
    expected = {
      remote_identifier: 'https://cdsic.ahrq.gov/sites/default/files/2023-05/FINALSRFLevel1EnvironmentalScan1.pdf',
      title: 'Standards and Regulatory Frameworks Workgroup: Environmental Scan',
      description: 'Clinical decision support (CDS) standards and regulatory frameworks make it possible for CDS tools ' \
                   'to be developed, shared, and implemented in various systems. PC CDS provides innovative ways to ' \
                   'ensure patients, caregivers, and care teams have patient-specific, evidence-based clinical guidance ' \
                   'to inform healthcare decision making. Consistent standards are essential to ensure PC CDS is accessible ' \
                   'wherever and whenever clinicians and patients prefer to receive it, and in a manner that is easy for both ' \
                   'groups to understand and act upon in both clinical and non-clinical settings.',
      url: 'https://cdsic.ahrq.gov/sites/default/files/2023-05/FINALSRFLevel1EnvironmentalScan1.pdf',
      published_on: Date.parse('Sun, 01 Jan 2023'),
      published_on_precision: 6,
      artifact_type: 'Environmental Scan',
      artifact_status: 'active',
      keywords: ['patient-centered', 'clinical decision support', 'standards', 'regulations', 'interoperability']
    }
    artifact = artifacts.first
    expected.each do |key, value|
      assert_equal(value, artifact.send(key))
    end
  end
end
