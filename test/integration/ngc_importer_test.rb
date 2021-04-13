# frozen_string_literal: true

class NgcImporterTest < ActiveSupport::TestCase
  test 'import sample NGC content into the database' do
    NgcImporter.send(:remove_const, :CACHE_DIR)
    NgcImporter.const_set(:CACHE_DIR, 'test/fixtures/files/ngc')
    index_mock = file_fixture('ngc_index.html').read
    stub_request(:get, /search/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: index_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'NGC').count)

    NgcImporter.run

    assert_equal(1, Repository.where(name: 'NGC').count)
    repository = Repository.where(name: 'NGC').first
    artifacts = repository.artifacts
    assert_equal(2, artifacts.count)

    artifact = artifacts.where(title: 'Environmental management of pediatric asthma. Guidelines for health care providers.').first
    assert(artifact.present?)
    assert_equal('Guideline', artifact.artifact_type)
    assert(artifact.keywords.include?('Asthma'))
    assert(artifact.keywords.include?('Counseling'))
  end
end
