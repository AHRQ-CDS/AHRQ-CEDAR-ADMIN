# frozen_string_literal: true

require 'application_system_test_case'

class RepositoriesTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    @repository = create_repository_with_artifacts(count: 2)
  end

  test 'repository functions as expected' do
    visit repository_url(@repository)
    assert_selector 'h1', text: @repository.name
    assert_selector 'h3', text: 'Artifacts By Status'
    assert_selector 'h3', text: 'Top 10 Keywords'
    assert_selector 'h3', text: 'Missing Attributes'
    assert_selector 'h3', text: 'Import Statistics'
    assert_selector 'canvas', count: 2
  end

  test 'repository is accessible' do
    visit repository_url(@repository)
    assert_axe_accessible(page)
  end
end
