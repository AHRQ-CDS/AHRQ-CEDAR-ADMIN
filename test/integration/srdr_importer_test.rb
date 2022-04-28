# frozen_string_literal: true

class SrdrImporterTest < ActiveSupport::TestCase
  test 'import SRDR data dump into the database' do
    # Load sample data for mocking
    artifact_list_mock = file_fixture('srdr_artifact_list.json').read

    # Stub out requests and return mock data as appropriate
    stub_request(:get, /public_projects.json/).to_return(status: 200, body: artifact_list_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'SRDR').count)

    # Load the mock records
    SrdrImporter.run

    # Ensure that all the expected data is loaded
    assert_equal(1, Repository.where(alias: 'SRDR').count)

    repository = Repository.where(alias: 'SRDR').first
    artifacts = repository.artifacts
    assert_equal(6, artifacts.count)

    artifact_1343 = artifacts.where(remote_identifier: '1343').first
    assert_equal('SRDR-PLUS-1343', artifact_1343.cedar_identifier)
    assert_equal('1343', artifact_1343.remote_identifier)
    assert_equal(1, artifact_1343.keywords.size)
    assert_equal('colorectal neoplasms', artifact_1343.keywords[0])
    assert_match(/The lack of evidence for PET/, artifact_1343.title)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description_html)
    assert_match(/Systematic review of diagnostic accuracy and clinical impact of PET and PET-CT/, artifact_1343.description_markdown)
    assert_match('http://DUMMY-URL/public_data?id=1343&type=project', artifact_1343.url)
    assert_equal('10.7301/Z08G8HMP', artifact_1343.doi)
    assert_equal(Date.parse('23 Jul 2015'), artifact_1343.published_on)
    assert_equal('active', artifact_1343.artifact_status)

    # Check tracking
    assert_equal(1, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(6, import_run.total_count)
    assert_equal(6, import_run.new_count)
    assert_equal(0, import_run.update_count)
  end
end
