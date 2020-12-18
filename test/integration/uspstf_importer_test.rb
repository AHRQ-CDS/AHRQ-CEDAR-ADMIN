require 'test_helper'
require_relative '../../lib/importers/uspstf'

class UspstfImporterTest < ActiveSupport::TestCase
  test "import USPSTF data dump into the database" do
    uspstf_importer = Importers::UspstfRepositoryImporter.new(file_fixture('uspstf_sample.json').read)
    uspstf_importer.update_db
    artifact = Artifact.find_by(remote_identifier: '358')
    assert(artifact.present?)
    assert_equal('Cervical Cancer: Screening --Women aged 21 to 65 years', artifact.title)
    assert_equal(Repository::USPSTF, artifact.repository.name)
    assert_equal(1, artifact.artifact_types.count)
    assert_equal(ArtifactType::RECOMMENDATION, artifact.artifact_types.first.name)
  end
end
