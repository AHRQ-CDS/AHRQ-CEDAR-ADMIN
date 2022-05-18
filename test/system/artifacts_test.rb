# frozen_string_literal: true

require 'application_system_test_case'

class ArtifactsTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    @repository = create(:repository)
    @artifact = create(:artifact, repository: @repository, description: nil, keywords: [], artifact_status: 'draft')
  end

  test 'artifact functions as expected' do
    visit artifact_url(@artifact)
    assert_selector 'h1', text: 'Artifact: ' + @artifact.title
    assert_selector 'strong', text: 'Keywords:'
    assert_selector 'strong', text: 'Keywords:'
    assert_selector 'a', text: @repository.name
    assert_selector 'strong', text: 'URL:'
    assert_selector 'strong', text: 'Type:'
    assert_selector 'strong', text: 'Status:'
    assert_selector 'strong', text: 'DOI:'
    assert_selector 'strong', text: 'Published On:'
    assert_selector 'strong', text: 'Indexed At:'
    assert_selector 'h4', text: 'Version History'
  end

  test 'artifact is accessible' do
    visit artifact_url(@artifact)
    assert_axe_accessible(page)
  end
end
