# frozen_string_literal: true

class EhcImporterTest < ActiveSupport::TestCase
  test 'import sample EHC content into the database' do
    # Load sample data for mocking
    artifact_list_mock = file_fixture('ehc_product_feed.xml').read

    # Stub out all request and return mock data as appropriate
    stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: artifact_list_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'EHC').count)

    # Load the mock records
    EhcImporter.download_and_update!

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(name: 'EHC').count)

    repository = Repository.where(name: 'EHC').first
    artifacts = repository.artifacts
    assert_equal(2, artifacts.count)

    artifact = artifacts.where(title: 'Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain').first
    assert(artifact.present?)
    assert(artifact.keywords.include?('Chronic Pain'))
    assert(artifact.mesh_keywords.include?('Chronic Pain'))

    artifact = artifacts.where(title: 'Treatments for Seasonal Allergic Rhinitis').first
    assert(artifact.present?)
    assert(artifact.mesh_keywords.include?('Hay Fever'))
  end
end
