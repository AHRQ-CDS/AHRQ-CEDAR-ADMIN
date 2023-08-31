# frozen_string_literal: true

class CdsicImporterTest < ActiveSupport::TestCase
  test 'import sample CDSiC content into the database' do
    # Sample data for mocking
    index_html = file_fixture('cdsic_index.html')
    viewpoints_html = file_fixture('cdsic_viewpoints.html')
    resource_html = file_fixture('cdsic_resource_page.html')
    viewpoint_html = file_fixture('cdsic_viewpoint_page.html')

    # Stub out requests and return mock data
    stub_request(:get, /srf-environmental-scan-report/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: resource_html)
    stub_request(:get, /workgroup-viewpoint/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: viewpoint_html)
    stub_request(:get, %r{cdsic/resources}).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: index_html)
    stub_request(:get, %r{cdsic/cdsic-leadership-viewpoints}).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: viewpoints_html)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'CDSiC').count)

    # Load the mock records
    CdsicImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'CDSiC').count)
    artifacts = Repository.where(alias: 'CDSiC').first.artifacts.sort_by(&:created_at)

    assert_equal(2, artifacts.count)
    expected = {
      remote_identifier: 'https://cdsic.ahrq.gov/cdsic/srf-environmental-scan-report',
      title: 'Standards and Regulatory Frameworks Workgroup: Environmental Scan',
      description: 'Clinical decision support (CDS) standards and regulatory frameworks make it possible for CDS tools ' \
                   'to be developed, shared, and implemented in various systems. PC CDS provides innovative ways to ' \
                   'ensure patients, caregivers, and care teams have patient-specific, evidence-based clinical guidance ' \
                   'to inform healthcare decision making. Consistent standards are essential to ensure PC CDS is accessible ' \
                   'wherever and whenever clinicians and patients prefer to receive it, and in a manner that is easy for both ' \
                   'groups to understand and act upon in both clinical and non-clinical settings.',
      url: 'https://cdsic.ahrq.gov/cdsic/srf-environmental-scan-report',
      published_on: Date.parse('Sun, 01 Jan 2023'),
      published_on_precision: 6,
      artifact_type: 'CDSiC Artifact',
      artifact_status: 'active',
      keywords: ['clinical decision support systems', 'patient-centered clinical decision support', 'regulation', 'data standards',
                 'cds implementation', 'cds development', 'cds adoption', 'research report', 'stakeholder center workgroup product']
    }
    artifact = artifacts.first
    expected.each do |key, value|
      assert_equal(value, artifact.send(key))
    end
    expected = {
      remote_identifier: 'https://cdsic.ahrq.gov/cdsic/workgroup-viewpoint',
      title: 'Moving the Needle on Advancing Patient-Centered Clinical Decision Support through the CDSiC’s Four Workgroups',
      url: 'https://cdsic.ahrq.gov/cdsic/workgroup-viewpoint',
      published_on: Date.parse('03 Feb 2023'),
      published_on_precision: 6,
      artifact_type: 'CDSiC Artifact',
      artifact_status: 'active'
    }
    artifact = artifacts.last
    expected.each do |key, value|
      assert_equal(value, artifact.send(key))
    end
  end
end
