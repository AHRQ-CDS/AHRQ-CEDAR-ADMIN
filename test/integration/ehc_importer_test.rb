# frozen_string_literal: true

class EhcImporterTest < ActiveSupport::TestCase
  test 'import sample EHC content into the database' do
    with_versioning do
      # Load sample data for mocking
      artifact_list_mock = file_fixture('ehc_product_feed.xml').read

      # Stub out all request and return mock data as appropriate
      stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: artifact_list_mock)

      # Ensure that none are loaded before the test runs
      assert_equal(0, Repository.where(alias: 'EHC').count)

      # Load the mock records
      EhcImporter.run

      # Ensure that all the expected data is loaded
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(2, artifacts.count)

      artifact = artifacts.where(title: 'Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('chronic pain'))
      assert_equal(Date.parse('March 24, 2021'), artifact.published_on)
      assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
      assert_equal(artifact.artifact_status, 'active')
      assert_equal(1, artifact.versions.length)
      assert_equal('create', artifact.versions.last.event)

      artifact = artifacts.where(title: 'Treatments for Seasonal Allergic Rhinitis').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('hay fever'))
      assert_equal(Date.parse('July 16, 2013'), artifact.published_on)
      assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
      assert_equal(artifact.artifact_status, 'archived')
      assert_equal(1, artifact.versions.length)
      assert_equal('create', artifact.versions.last.event)

      # Check tracking
      assert_equal(1, repository.import_runs.count)
      import_run = repository.import_runs.last
      assert_equal('success', import_run.status)
      assert_equal(2, import_run.total_count)
      assert_equal(2, import_run.new_count)
      assert_equal(0, import_run.update_count)

      # Run importer a second time with one of the previously imported artifacts missing
      # Load sample data for mocking
      artifact_list_mock = file_fixture('ehc_product_feed_2.xml').read

      # Stub out all request and return mock data as appropriate
      stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: artifact_list_mock)

      # Load the mock records
      EhcImporter.run

      # Ensure that all the expected data is still present
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(2, artifacts.count)

      artifact = artifacts.where(title: 'Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('chronic pain'))
      assert_equal(artifact.artifact_status, 'active')
      assert_equal(1, artifact.versions.length)
      assert_equal('create', artifact.versions.last.event)

      artifact = artifacts.where(title: 'Treatments for Seasonal Allergic Rhinitis').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('hay fever'))
      assert_equal(artifact.artifact_status, 'retracted')
      assert_equal(2, artifact.versions.length)
      assert_equal('retract', artifact.versions.last.event)

      # Check tracking
      assert_equal(2, repository.import_runs.count)
      import_run = repository.import_runs.last
      assert_equal('success', import_run.status)
      assert_equal(1, import_run.total_count)
      assert_equal(0, import_run.new_count)
      assert_equal(0, import_run.update_count)
      assert_equal(1, import_run.delete_count)
    end
  end
end
