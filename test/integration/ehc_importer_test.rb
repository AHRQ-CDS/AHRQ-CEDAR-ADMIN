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

      # Run importer a second time with one of the previously imported artifacts missing and a new
      # artifact present
      # Load sample data for mocking
      ENV['suppress_large_change_detection'] = 'false'
      artifact_list_mock = file_fixture('ehc_product_feed_2.xml').read

      # Stub out all request and return mock data as appropriate
      stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: artifact_list_mock)

      # Load the mock records
      EhcImporter.run

      # Ensure that all the expected data is still present
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(3, artifacts.count)

      artifact = artifacts.where(title: 'Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('chronic pain'))
      assert_equal(artifact.artifact_status, 'active')
      assert_equal(1, artifact.versions.length)
      assert_equal('create', artifact.versions.last.event)

      artifact = artifacts.where(title: 'Treatments for Seasonal Allergic Rhinitis').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('hay fever'))
      assert_equal('archived', artifact.artifact_status)
      assert_equal(3, artifact.versions.length)
      assert_equal('suppress', artifact.versions.last.event)

      artifact = artifacts.where(title: 'A New Artifact').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('chronic pain'))
      assert_equal('suppressed', artifact.artifact_status)
      assert_equal(2, artifact.versions.length)
      assert_equal('suppress', artifact.versions.last.event)

      # Check tracking
      assert_equal(2, repository.import_runs.count)
      import_run = repository.import_runs.last
      assert_equal('flagged', import_run.status)
      assert_equal(2, import_run.total_count)
      assert_equal(1, import_run.new_count)
      assert_equal(0, import_run.update_count)
      assert_equal(1, import_run.delete_count)

      # run once more with large change detection off
      ENV['suppress_large_change_detection'] = 'true'
      repository.enabled = true
      repository.save!
      EhcImporter.run

      # Ensure that all the expected data is still present
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(3, artifacts.count)

      artifact = artifacts.where(title: 'Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('chronic pain'))
      assert_equal(artifact.artifact_status, 'active')
      assert_equal(1, artifact.versions.length)
      assert_equal('create', artifact.versions.last.event)

      artifact = artifacts.where(title: 'Treatments for Seasonal Allergic Rhinitis').first
      assert(artifact.present?)
      assert(artifact.keywords.include?('hay fever'))
      assert_equal('retracted', artifact.artifact_status)
      assert_equal(4, artifact.versions.length)
      assert_equal('retract', artifact.versions.last.event)

      # Check tracking
      assert_equal(3, repository.import_runs.count)
      import_run = repository.import_runs.last
      assert_equal('success', import_run.status)
      assert_equal(2, import_run.total_count)
      assert_equal(0, import_run.new_count)
      assert_equal(1, import_run.update_count)
      assert_equal(1, import_run.delete_count)
    end
  end

  test 'handle missing EHC content' do
    with_versioning do
      # Load sample data for mocking
      response_1 = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <response>
        <item key=\"0\">
          <Title>Living Systematic Review on Cannabis and Other Plant-Based Treatments for Chronic Pain</Title>
          <Link>https://effectivehealthcare.ahrq.gov/products/plant-based-chronic-pain-treatment/living-review</Link>
          <Author-Name>lnawrocki</Author-Name>
          <Description>A systematic review assessing the effectiveness and harms of plant-based treatments for chronic pain</Description>
          <Health-Topics>Chronic Pain</Health-Topics>
          <Product-Type>Surveillance Report</Product-Type>
          <Publish-Date>March 24, 2021</Publish-Date>
          <Status></Status>
          <Keywords>Cannabis, Chronic Pain, Mycetozoa</Keywords>
          <Citation></Citation>
        </item>
      </response>"

      # Stub out all request and return mock data as appropriate
      stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: response_1)

      # Ensure that none are loaded before the test runs
      assert_equal(0, Repository.where(alias: 'EHC').count)

      # Load the mock records
      EhcImporter.run

      # Ensure that all the expected data is loaded
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(1, artifacts.count)

      artifact = artifacts.where(remote_identifier: 'https://effectivehealthcare.ahrq.gov/products/plant-based-chronic-pain-treatment/living-review').first
      assert(artifact.present?)
      assert_equal(artifact.artifact_status, 'active')

      response_2 = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <response>
        <item key=\"0\">
          <Title>Treatments for Seasonal Allergic Rhinitis</Title>
          <Link>https://effectivehealthcare.ahrq.gov/products/allergy-seasonal/research</Link>
          <Author-Name>bahdevteam19</Author-Name>
          <Description>Objectives: This review compared the effectiveness and common adverse events of medication</Description>
          <Health-Topics>Immune System and Disorders,Hay Fever</Health-Topics>
          <Product-Type>Systematic Review</Product-Type>
          <Publish-Date>July 16, 2013</Publish-Date>
          <Status>Archived</Status>
          <Keywords>Mycetozoa</Keywords>
          <Citation>Glacy J, Putnam K, Godfrey S, Falzon L, Mauger B, Samson D, Aronson N. Treatments for Seasonal Allergic Rhinitis.</Citation>
        </item>
      </response>"

      stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: response_2)

      EhcImporter.run

      # Ensure that all the expected data is loaded
      assert_equal(1, Repository.where(alias: 'EHC').count)

      repository = Repository.where(alias: 'EHC').first
      artifacts = repository.artifacts
      assert_equal(2, artifacts.count)

      previous_imported_artifact = artifacts.where(remote_identifier: 'https://effectivehealthcare.ahrq.gov/products/plant-based-chronic-pain-treatment/living-review')
      assert_equal(1, previous_imported_artifact.count)
      assert_equal(previous_imported_artifact.first.artifact_status, 'retracted')
    end
  end
end
