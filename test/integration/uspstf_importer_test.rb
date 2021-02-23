# frozen_string_literal: true

require 'test_helper'

class UspstfImporterTest < ActiveSupport::TestCase
  test 'import partial USPSTF data dump into the database' do
    # Load sample data for mocking
    artifact_list_mock = file_fixture('uspstf_sample.json').read
    pdf_tool_mock = file_fixture('uspstf_tool.pdf')
    html_tool_mock = file_fixture('uspstf_tool.html')

    # Stub out all request and return mock data as appropriate
    stub_request(:get, %r{api/json}).to_return(status: 200, body: artifact_list_mock)
    stub_request(:get, /cervical-cancer-screening2/).to_return(status: 200, headers: { 'Content-Type' => 'application/pdf' }, body: pdf_tool_mock)
    stub_request(:get, /jamanetwork.com/).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: html_tool_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(name: 'USPSTF').count)

    # Import sample data
    UspstfImporter.download_and_update!

    # Check that all of the expected data was imported
    repository = Repository.where(name: 'USPSTF').first
    artifacts = repository.artifacts
    assert_equal(7, artifacts.count)

    # Check example specific recommendation
    artifact = artifacts.where(cedar_identifier: 'USPSTF-SR-358').first
    assert_equal('Cervical Cancer: Screening --Women aged 21 to 65 years', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('Specific Recommendation', artifact.artifact_type)

    # Check example general recommendation
    artifact = artifacts.where(cedar_identifier: 'USPSTF-GR-199').first
    assert_equal('Screening for Cervical Cancer', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('General Recommendation', artifact.artifact_type)

    # Check example PDF tool
    artifact = artifacts.where(cedar_identifier: 'USPSTF-TOOL-323').first
    assert_equal('Cervical Cancer Screening - Clinical Summary (PDF)', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('Tool', artifact.artifact_type)
    assert_equal('This is a sample tool for the USPSTF importer.', artifact.description)

    # Check example HTML tool
    artifact = artifacts.where(cedar_identifier: 'USPSTF-TOOL-324').first
    assert_equal('Cervical Cancer Screening - Patient Page', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('Tool', artifact.artifact_type)
    assert_equal('A sample HTML USPSTF tool', artifact.description)
    assert(artifact.keywords.include?('uspstf'))
    assert(artifact.keywords.include?('tool'))

    # Import sample data a second time
    UspstfImporter.download_and_update!

    #  Check if any artifacts were duplicated by second import
    artifacts = Artifact.where(cedar_identifier: 'USPSTF-SR-358')
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: 'USPSTF-GR-199')
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: 'USPSTF-TOOL-323')
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: 'USPSTF-TOOL-324')
    assert_equal(1, artifacts.count)
  end
end
