# frozen_string_literal: true

class EpcImporterTest < ActiveSupport::TestCase
  test 'import sample EPC content into the database' do
    # Load sample data for mocking
    artifact_list_1_mock = file_fixture('epc_artifact_list_1.html').read
    artifact_list_2_mock = file_fixture('epc_artifact_list_2.html').read
    artifact_mock = file_fixture('epc_artifact.html').read
    metadata_mock = file_fixture('epc_nih_metadata.xml').read

    # Stub out all request and return mock data as appropriate
    stub_request(:get, /search.html\?page=0/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_1_mock)
    stub_request(:get, /search.html\?page=1/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_list_2_mock)
    stub_request(:get, /management-infantile-epilepsy/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /palliative-care-integration/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /carotid-artery-stenosis-screening/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)
    stub_request(:get, /NBK293871/).to_return(status: 403)
    stub_request(:get, /oai:books.ncbi.nlm.nih.gov:293871/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: metadata_mock)
    stub_request(:get, /non-existant/).to_return(status: 404)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'EPC').count)

    # Load the mock records
    EpcImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'EPC').count)

    repository = Repository.where(alias: 'EPC').first
    artifacts = repository.artifacts
    assert_equal(4, artifacts.count)

    artifact = artifacts.where(title: 'Integrating Palliative Care in Ambulatory Care of Noncancer Serious Chronic Illness: A Systematic Review').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))
    assert(artifact.keywords.include?('a and b'))
    assert_equal(Date.new(2021, 2), artifact.published_on)
    assert_equal(2, artifact.published_on_precision) # MONTH PRECISION = 2
    assert_equal('archived', artifact.artifact_status)

    artifact = artifacts.where(title: 'Screening for Asymptomatic Carotid Artery Stenosis in the General Population').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))
    assert_equal(Date.new(2021, 3), artifact.published_on)
    assert_equal(2, artifact.published_on_precision) # MONTH PRECISION = 1

    artifact = artifacts.where(title: 'Management of Infantile Epilepsy').first
    assert(artifact.present?)
    assert_equal('A sample HTML EPC product', artifact.description)
    assert(artifact.keywords.include?('epc'))
    assert_equal(Date.new(2020), artifact.published_on)
    assert_equal(1, artifact.published_on_precision) # YEAR PRECISION = 1

    artifact = artifacts.where(title: 'Screening for Abnormal Glucose and Type 2 Diabetes Mellitus').first
    assert(artifact.present?)
    assert_equal(artifact.description, 'Type 2 diabetes mellitus (DM) is the leading cause of kidney failure.')
    assert_equal(Date.new(2015, 5, 12), artifact.published_on)
    assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 1

    # Check tracking
    assert_equal(1, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(5, import_run.total_count)
    assert_equal(4, import_run.new_count)
    assert_equal(0, import_run.update_count)
    assert_equal(1, import_run.error_msgs.size)
    assert_equal(0, import_run.warning_msgs.size)
  end
end
