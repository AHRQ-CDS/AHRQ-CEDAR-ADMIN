# frozen_string_literal: true

class EhcImporterTest < ActiveSupport::TestCase
  test 'import sample EHC content into the database' do
    # Load sample data for mocking
    artifact_list_1_mock = file_fixture('ehc_artifact_list_1.html').read
    artifact_list_2_mock = file_fixture('ehc_artifact_list_2.html').read
    artifact_mock = file_fixture('ehc_artifact.html').read

    # Stub out all request and return mock data as appropriate
    stub_request(:get, %r{/products\?page=1}).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_2_mock)
    stub_request(:get, %r{/products$}).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_1_mock)
    stub_request(:get, /management-infantile-epilepsy/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /rural-telehealth/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /immunity-after-covid/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'EHC').count)

    # Load the mock records
    EhcImporter.download_and_update!

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(name: 'EHC').count)

    repository = Repository.where(name: 'EHC').first
    artifacts = repository.artifacts
    assert_equal(3, artifacts.count)

    artifact = artifacts.where(title: 'Management of Infantile Epilepsy').first
    assert(artifact.present?)
    assert_equal('A sample HTML EHC product', artifact.description)
    assert(artifact.keywords.include?('ehc'))

    artifact = artifacts.where(title: 'Improving Rural Health Through Telehealth-Guided Provider-to-Provider Communication').first
    assert(artifact.present?)
    assert_equal('A sample HTML EHC product', artifact.description)
    assert(artifact.keywords.include?('ehc'))

    artifact = artifacts.where(title: 'Immunity After COVID-19').first
    assert(artifact.present?)
    assert_equal('A sample HTML EHC product', artifact.description)
    assert(artifact.keywords.include?('ehc'))
  end
end
