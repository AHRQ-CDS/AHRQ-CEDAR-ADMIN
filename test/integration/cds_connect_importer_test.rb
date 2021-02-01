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
    stub_request(:get, /cds_api.1186/).to_return(status: 200, body: artifact_1186_mock)
    stub_request(:post, /logout/).to_return(status: 200)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'CDS Connect').count)

    # Load the mock records
    CdsConnectImporter.download_and_update!

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(name: 'CDS Connect').count)

    repository = Repository.where(name: 'CDS Connect').first
    artifacts = repository.artifacts
    assert_equal(2, artifacts.count)

    artifact_1186 = artifacts.where(title: 'Facilitating Shared Decision Making For People Who Drink Alcohol: A Patient Decision Aid').first
    assert(artifact_1186.present?)
    assert_match(/This CDS artifact identifies patients screened for alcohol use/, artifact_1186.description)
    assert_equal(['alcohol', 'brief intervention', 'decision aid', 'excessive alcohol use'], artifact_1186.keywords)
    assert_equal(['Preventive Health Services', 'Alcohol Drinking', 'Risk Assessment', 'Substance Abuse Detection'], artifact_1186.mesh_keywords)
    assert_equal('https://cdsconnect.ahrqstg.org/node/1186', artifact_1186.url)
    assert_equal(Date.parse('Thu, 16 Jul 2020'), artifact_1186.published_on)
    assert_equal('Data Summary', artifact_1186.artifact_type)

    artifact_1221 = artifacts.where(title: 'Managing chronic pain with Prescription Drug Monitoring Program (PDMP) medication dispense data').first
    assert(artifact_1221.present?)
    assert_match(/This artifact implements access to Prescription Drug Monitoring/, artifact_1221.description)
    assert_equal(['Chronic Pain', 'Analgesics, Opioid', 'Prescription Drug Misuse', 'risk assessment', 'Pain Assessment'], artifact_1221.keywords)
    assert_equal(['Analgesics, Opioid', 'Opioid-Related Disorders', 'Pain Management'], artifact_1221.mesh_keywords)
    assert_equal('https://cdsconnect.ahrqstg.org/node/1221', artifact_1221.url)
    assert_nil(artifact_1221.published_on)
    assert_equal('Data Summary', artifact_1221.artifact_type)
  end
end
