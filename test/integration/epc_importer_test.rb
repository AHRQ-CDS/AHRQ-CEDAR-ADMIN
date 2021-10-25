# frozen_string_literal: true

class EpcImporterTest < ActiveSupport::TestCase
  test 'import sample EPC content into the database' do
    # Load sample data for mocking
    artifact_list_1_mock = file_fixture('epc_artifact_list_1.html').read
    artifact_list_2_mock = file_fixture('epc_artifact_list_2.html').read
    artifact_mock = file_fixture('epc_artifact.html').read

    # Stub out all request and return mock data as appropriate
    stub_request(:get, /search.html\?page=0/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_1_mock)
    stub_request(:get, /search.html\?page=1/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_2_mock)
    stub_request(:get, /management-infantile-epilepsy/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /palliative-care-integration/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /carotid-artery-stenosis-screening/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /non-existant/).to_return(status: 404)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'EPC').count)

    # Load the mock records
    EpcImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'EPC').count)

    repository = Repository.where(alias: 'EPC').first
    artifacts = repository.artifacts
    assert_equal(3, artifacts.count)

    artifact = artifacts.where(title: 'Integrating Palliative Care in Ambulatory Care of Noncancer Serious Chronic Illness: A Systematic Review').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))

    artifact = artifacts.where(title: 'Screening for Asymptomatic Carotid Artery Stenosis in the General Population').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))

    artifact = artifacts.where(title: 'Management of Infantile Epilepsy').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))

    # Check tracking
    assert_equal(1, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(4, import_run.total_count)
    assert_equal(3, import_run.new_count)
    assert_equal(0, import_run.update_count)
    assert_equal(1, import_run.error_msgs.size)
    assert_equal(3, import_run.warning_msgs.size)
  end
end
