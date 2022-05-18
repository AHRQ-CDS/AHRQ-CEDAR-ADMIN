# frozen_string_literal: true

require 'application_system_test_case'

class KeywordsTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    repository = create_repository_with_artifacts(count: 1)
    @keyword = repository.artifacts.first.keywords.first
  end

  test 'keyword functions as expected' do
    visit keyword_url(@keyword)
    assert_selector 'h1', text: @keyword
    assert_selector 'h3', text: 'Artifacts By Repository'
    assert_selector 'h3', text: 'Top Related Keywords'
    assert_selector 'h3', text: '1 Artifacts'
    assert_selector 'canvas', count: 2
  end

  test 'keyword is accessible' do
    visit keyword_url(@keyword)
    assert_axe_accessible(page)
  end
end
