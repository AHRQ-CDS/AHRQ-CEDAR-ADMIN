# frozen_string_literal: true

class CedarImporterTest < ActiveSupport::TestCase
  test 'Repository attributes are appropriately updated' do
    # Set up a repository importer with attributes and run it so the repository gets created
    # rubocop:disable Lint/ConstantDefinitionInBlock
    class TestRepositoryImporter < CedarImporter
      repository_name 'NAME'
      repository_alias 'ALIAS'
      repository_home_page 'HOMEPAGE'
      repository_description 'DESCRIPTION'
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock
    TestRepositoryImporter.run

    # Make sure the repository got created with the right attributes
    assert_equal(Repository.count, 1)
    repository = Repository.where(name: 'NAME').first
    assert_not_nil(repository)
    assert_equal('ALIAS', repository.alias)
    assert_equal('HOMEPAGE', repository.home_page)
    assert_equal('DESCRIPTION', repository.description)

    # Update the existing repository importer with new attribute values and run it
    # rubocop:disable Lint/ConstantDefinitionInBlock
    class TestRepositoryImporter < CedarImporter
      repository_name 'NAME'
      repository_alias 'NEWALIAS'
      repository_home_page 'NEWHOMEPAGE'
      repository_description 'NEWDESCRIPTION'
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock
    TestRepositoryImporter.run

    # Make sure the previously created repository has been updated
    assert_equal(Repository.count, 1)
    updated_repository = Repository.where(name: 'NAME').first
    assert_not_nil(updated_repository)
    assert_equal(repository.id, updated_repository.id)
    assert_equal('NEWALIAS', updated_repository.alias)
    assert_equal('NEWHOMEPAGE', updated_repository.home_page)
    assert_equal('NEWDESCRIPTION', updated_repository.description)
  end
end
