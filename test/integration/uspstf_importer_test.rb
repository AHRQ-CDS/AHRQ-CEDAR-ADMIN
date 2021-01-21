# frozen_string_literal: true

require 'test_helper'

class UspstfImporterTest < ActiveSupport::TestCase
  test 'import USPSTF data dump into the database' do
    # Import sample data
    uspstf_importer = UspstfImporter.new(file_fixture('uspstf_sample.json').read)
    uspstf_importer.update_db!

    # Check example specific recommendation
    artifacts = Artifact.where(remote_identifier: 'USPSTF-SR-358')
    assert_equal(1, artifacts.count)
    artifact = artifacts.first
    assert_equal('Cervical Cancer: Screening --Women aged 21 to 65 years', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('Specific Recommendation', artifact.artifact_type)

    # Check example general recommendation
    artifacts = Artifact.where(remote_identifier: 'USPSTF-GR-38')
    assert_equal(1, artifacts.count)
    artifact = artifacts.first
    assert_equal('Rh (D) Incompatibility', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('General Recommendation', artifact.artifact_type)

    # Check example tool
    artifacts = Artifact.where(remote_identifier: 'USPSTF-TOOL-248')
    assert_equal(1, artifacts.count)
    artifact = artifacts.first
    assert_equal('5 A\'s Behavioral Counseling Framework - Tobacco Cessation', artifact.title)
    assert_equal('USPSTF', artifact.repository.name)
    assert_equal('Tool', artifact.artifact_type)

    # Import sample data a second time
    uspstf_importer.update_db!

    #  Check if any artifactsare duplicated by second import
    artifacts = Artifact.where(remote_identifier: 'USPSTF-SR-358')
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(remote_identifier: 'USPSTF-GR-38')
    assert_equal(1, artifacts.count)
    artifacts = Artifact.where(remote_identifier: 'USPSTF-TOOL-248')
    assert_equal(1, artifacts.count)
  end
end
