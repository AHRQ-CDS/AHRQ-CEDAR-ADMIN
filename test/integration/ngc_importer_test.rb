# frozen_string_literal: true

class NgcImporterTest < ActiveSupport::TestCase
  test 'import sample NGC content into the database' do
    NgcImporter.send(:remove_const, :CACHE_DIR)
    NgcImporter.const_set(:CACHE_DIR, 'test/fixtures/files/ngc')
    index_mock = file_fixture('ngc_index.html').read
    stub_request(:get, /search/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: index_mock)
    stub_request(:get, %r{/summaries/downloadcontent/ngc-999999}).to_return(status: 404)
    stub_request(:get, %r{/summaries/summary/999999/non-existant}).to_return(status: 404)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'NGC').count)

    NgcImporter.run

    assert_equal(1, Repository.where(alias: 'NGC').count)
    repository = Repository.where(alias: 'NGC').first
    artifacts = repository.artifacts
    assert_equal(2, artifacts.count)

    artifact = artifacts.where(title: 'Environmental management of pediatric asthma. Guidelines for health care providers.').first
    assert(artifact.present?)
    assert_equal('Guideline', artifact.artifact_type)
    assert(artifact.keywords.include?('asthma'))
    assert(artifact.keywords.include?('counseling'))

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
