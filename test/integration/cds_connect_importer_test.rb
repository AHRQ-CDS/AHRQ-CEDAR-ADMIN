# frozen_string_literal: true

class CdsConnectImporterTest < ActiveSupport::TestCase
  test 'import partial CDS Connect data dump into the database' do
    # Load sample data for mocking
    artifact_list_mock = file_fixture('cds_connect_artifact_list.json').read
    artifact_1221_mock = file_fixture('cds_connect_artifact_1221.json').read
    artifact_1186_mock = file_fixture('cds_connect_artifact_1186.json').read

    # Stub out all request and return mock data as appropriate
    stub_request(:post, /login/).to_return(status: 200)
    stub_request(:get, /artifacts/).to_return(status: 200, body: artifact_list_mock)
    stub_request(:get, /cds_api.1221/).to_return(status: 200, body: artifact_1221_mock)
    stub_request(:get, /cds_api.1234/).to_return(status: 404)
    stub_request(:get, /cds_api.1186/).to_return(status: 200, body: artifact_1186_mock)
    stub_request(:post, /logout/).to_return(status: 200)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'CDS Connect').count)

    # Load the mock records
    CdsConnectImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'CDS Connect').count)

    repository = Repository.where(alias: 'CDS Connect').first
    artifacts = repository.artifacts
    assert_equal(2, artifacts.count)

    artifact_1186 = artifacts.where(title: 'Facilitating Shared Decision Making For People Who Drink Alcohol: A Patient Decision Aid').first
    assert(artifact_1186.present?)
    assert_equal('CDS-CONNECT-1186', artifact_1186.cedar_identifier)
    assert_equal('1186', artifact_1186.remote_identifier)
    assert_match(/This CDS artifact identifies patients screened for alcohol use/, artifact_1186.description)
    assert_equal(['alcohol', 'brief intervention', 'decision aid', 'excessive alcohol use', 'preventive health services',
                  'alcohol drinking', 'risk assessment', 'substance abuse detection'], artifact_1186.keywords)
    assert_match(/node.1186/, artifact_1186.url)
    assert_equal(Date.parse('Thu, 16 Jul 2020'), artifact_1186.published_on)
    assert_equal(3, artifact_1186.published_on_precision) # DAY PRECISION = 3
    assert_equal('Data Summary', artifact_1186.artifact_type)
    assert_equal('draft', artifact_1186.artifact_status)
    assert_equal(0, artifact_1186.strength_of_recommendation_sort)
    assert_nil(artifact_1186.strength_of_recommendation_statement)
    assert_nil(artifact_1186.strength_of_recommendation_score)
    assert_equal(0, artifact_1186.quality_of_evidence_sort)
    assert_nil(artifact_1186.quality_of_evidence_statement)
    assert_nil(artifact_1186.quality_of_evidence_score)

    artifact_1221 = artifacts.where(title: 'Managing chronic pain with Prescription Drug Monitoring Program (PDMP) medication dispense data').first
    assert(artifact_1221.present?)
    assert_equal('CDS-CONNECT-1221', artifact_1221.cedar_identifier)
    assert_equal('1221', artifact_1221.remote_identifier)
    assert_match(/This artifact implements access to Prescription Drug Monitoring/, artifact_1221.description)
    assert_equal(['chronic pain', 'analgesics, opioid', 'prescription drug misuse', 'risk assessment', 'pain assessment',
                  'opioid-related disorders', 'pain management'], artifact_1221.keywords)
    assert_match(/node.1221/, artifact_1221.url)
    assert_nil(artifact_1221.published_on)
    assert_equal(0, artifact_1221.published_on_precision) # NONE PRECISION = 0
    assert_equal('Data Summary', artifact_1221.artifact_type)
    assert_equal('unknown', artifact_1221.artifact_status)
    assert_equal(0, artifact_1221.strength_of_recommendation_sort)
    assert_nil(artifact_1221.strength_of_recommendation_score)
    assert_equal('strength', artifact_1221.strength_of_recommendation_statement)
    assert_equal(0, artifact_1221.quality_of_evidence_sort)
    assert_nil(artifact_1221.quality_of_evidence_score)
    assert_equal('quality', artifact_1221.quality_of_evidence_statement)

    # Check tracking
    assert_equal(1, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(3, import_run.total_count)
    assert_equal(2, import_run.new_count)
    assert_equal(0, import_run.update_count)
    assert_equal(1, import_run.error_msgs.size)
  end
end
