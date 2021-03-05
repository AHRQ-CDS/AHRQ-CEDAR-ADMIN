# frozen_string_literal: true

class SrdrImporterTest < ActiveSupport::TestCase
  test 'import SRDR data dump into the database' do
    # Load sample data for mocking
    artifact_list_mock = file_fixture('srdr_artifact_list.json').read

    # Stub out requests and return mock data as appropriate
    stub_request(:get, /public_projects.json/).to_return(status: 200, body: artifact_list_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'SRDR').count)

    # Load the mock records
    SrdrImporter.download_and_update!

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(name: 'SRDR').count)

    repository = Repository.where(name: 'SRDR').first
    artifacts = repository.artifacts
    assert_equal(6, artifacts.count)

    artifact_1343 = artifacts.where(remote_identifier: '1343').first
    assert_equal('SRDR-PLUS-1343', artifact_1343.cedar_identifier)
    assert_equal('1343', artifact_1343.remote_identifier)
    assert_match(/The lack of evidence for PET/, artifact_1343.title)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description_html)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description_markdown)
    assert_match(/projects.1343/, artifact_1343.url)
    assert_equal('10.7301/Z08G8HMP', artifact_1343.doi)
    assert_equal(Date.parse('23 Jul 2015'), artifact_1343.published_on)
    assert_equal('unknown', artifact_1343.artifact_status)
  end
end