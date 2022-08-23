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
    stub_request(:get, %r{jama/fullarticle/1234567}).to_return(status: 404)
    stub_request(:get, %r{jama/fullarticle/2697698}).to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: html_tool_mock)

    # Ensure that none are loaded before the test runs
    assert_equal(0, Repository.where(alias: 'USPSTF').count)

    # Import sample data
    UspstfImporter.run

    # Check that all of the expected data was imported
    repository = Repository.where(alias: 'USPSTF').first
    artifacts = repository.artifacts
    assert_equal(7, artifacts.count)

    # Check example specific recommendation
    sr_358_id = "USPSTF-#{Digest::MD5.hexdigest('cervical-cancer-screening' + '358')}"
    artifact = artifacts.where(cedar_identifier: sr_358_id).first
    assert artifact.present?
    assert_equal('Cervical Cancer: Screening --Women aged 21 to 65 years', artifact.title)
    assert_equal('USPSTF', artifact.repository.alias)
    assert_equal('Specific Recommendation', artifact.artifact_type)
    assert_equal(2, artifact.strength_of_recommendation_sort)
    assert_equal('A', artifact.strength_of_recommendation_score)
    assert(artifact.strength_of_recommendation_statement.start_with?('The USPSTF recommends'))
    assert_equal('A', artifact.quality_of_evidence_score)
    assert(artifact.quality_of_evidence_statement.start_with?('The USPSTF strongly recommends'))
    assert_equal(Date.new(2018, 7, 23), artifact.published_on)
    assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
    assert(artifact.keywords.include?('screening'))
    assert(artifact.keywords.include?('cervical cancer'))
    assert(artifact.keywords.include?('pap smear'))
    assert(artifact.keywords.include?('hpv'))
    assert(artifact.keywords.include?('human papillomavirus'))
    assert(artifact.keywords.include?('hysterectomy'))
    assert(artifact.keywords.include?('cervix'))
    assert(artifact.keywords.include?('uspstf'))

    # Check example general recommendation
    gr_199_id = "USPSTF-#{Digest::MD5.hexdigest('cervical-cancer-screening')}"
    artifact = artifacts.where(cedar_identifier: gr_199_id).first
    assert artifact.present?
    assert_equal('Screening for Cervical Cancer', artifact.title)
    assert_equal('USPSTF', artifact.repository.alias)
    assert_equal('General Recommendation', artifact.artifact_type)
    assert_equal(2, artifact.strength_of_recommendation_sort)
    assert_nil(artifact.strength_of_recommendation_score)
    assert_equal(2, artifact.quality_of_evidence_sort)
    assert_equal(Date.new(2018, 7, 23), artifact.published_on)
    assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
    assert(artifact.keywords.include?('screening'))
    assert(artifact.keywords.include?('cervical cancer'))
    assert(artifact.keywords.include?('pap smear'))
    assert(artifact.keywords.include?('hpv'))
    assert(artifact.keywords.include?('human papillomavirus'))
    assert(artifact.keywords.include?('hysterectomy'))
    assert(artifact.keywords.include?('cervix'))
    assert(artifact.keywords.include?('uspstf'))

    # Check example PDF tool
    tool_323_id = "USPSTF-#{Digest::MD5.hexdigest('https://www.uspreventiveservicestaskforce.org/Page/Document/ClinicalSummaryFinal/cervical-cancer-screening2')}"
    artifact = artifacts.where(cedar_identifier: tool_323_id).first
    assert artifact.present?
    assert_equal('Cervical Cancer Screening - Clinical Summary (PDF)', artifact.title)
    assert(artifact.keywords.include?('hpv'))
    assert_equal('USPSTF', artifact.repository.alias)
    assert_equal('Tool', artifact.artifact_type)
    assert_equal('This is a sample tool for the USPSTF importer.', artifact.description)
    assert_equal(Date.new(2021, 2, 9), artifact.published_on)
    assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
    assert(artifact.keywords.include?('clinical summary'))
    assert(artifact.keywords.include?('cervical cancer'))
    assert(artifact.keywords.include?('screening'))
    assert(artifact.keywords.include?('cervical cancer'))
    assert(artifact.keywords.include?('pap smear'))
    assert(artifact.keywords.include?('hpv'))
    assert(artifact.keywords.include?('human papillomavirus'))
    assert(artifact.keywords.include?('hysterectomy'))
    assert(artifact.keywords.include?('cervix'))
    assert(artifact.keywords.include?('uspstf'))

    # Check example HTML tool
    tool_324_id = "USPSTF-#{Digest::MD5.hexdigest('https://jamanetwork.com/journals/jama/fullarticle/2697698')}"
    artifact = artifacts.where(cedar_identifier: tool_324_id).first
    assert artifact.present?
    assert_equal('Cervical Cancer Screening - Patient Page', artifact.title)
    assert_equal('USPSTF', artifact.repository.alias)
    assert_equal('Tool', artifact.artifact_type)
    assert_equal('A sample HTML USPSTF tool', artifact.description)
    assert_equal(Date.new(2018, 7, 23), artifact.published_on)
    assert_equal(3, artifact.published_on_precision) # DAY PRECISION = 3
    assert(artifact.keywords.include?('tool'))
    assert(artifact.keywords.include?('one'))
    assert(artifact.keywords.include?('two'))
    assert(artifact.keywords.include?('three'))
    assert(artifact.keywords.include?('four'))
    assert(artifact.keywords.include?('five'))
    assert(artifact.keywords.include?('six'))
    assert(artifact.keywords.include?('seven'))
    assert(artifact.keywords.include?('screening'))
    assert(artifact.keywords.include?('cervical cancer'))
    assert(artifact.keywords.include?('pap smear'))
    assert(artifact.keywords.include?('hpv'))
    assert(artifact.keywords.include?('human papillomavirus'))
    assert(artifact.keywords.include?('hysterectomy'))
    assert(artifact.keywords.include?('cervix'))
    assert(artifact.keywords.include?('uspstf'))

    # Check tracking
    assert_equal(1, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(7, import_run.total_count)
    assert_equal(7, import_run.new_count)
    assert_equal(0, import_run.update_count)
    assert_equal(0, import_run.error_msgs.size)

    # Import sample data a second time
    UspstfImporter.run

    #  Check if any artifacts were duplicated by second import
    artifacts = Artifact.where(cedar_identifier: sr_358_id)
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: gr_199_id)
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: tool_323_id)
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(cedar_identifier: tool_324_id)
    assert_equal(1, artifacts.count)

    # Check tracking
    assert_equal(2, repository.import_runs.count)
    import_run = repository.import_runs.last
    assert_equal('success', import_run.status)
    assert_equal(7, import_run.total_count)
    assert_equal(0, import_run.new_count)
    assert_equal(0, import_run.update_count)
    assert_equal(0, import_run.error_msgs.size)
  end
end
