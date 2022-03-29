# frozen_string_literal: true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase
  test 'home functions as expected' do
    sign_in create(:user)
    repository_1 = create_repository_with_artifacts(count: 2)
    repository_2 = create(:repository)
    create(:artifact, repository: repository_2, description: nil, keywords: [], artifact_status: 'draft')
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 1, update_count: 1, delete_count: 1)
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 0, update_count: 1, delete_count: 1)
    keyword = repository_1.artifacts.first.keywords.first
    create(:search_log)

    visit '/home'
    assert_selector 'h1', text: 'CEDAR Statistics'

    assert_selector 'h3', text: 'Artifacts Per Repository'
    assert_selector 'h3', text: 'Import Statistics'
    page.has_link? 'Repository 1', count: 3

    assert_selector 'h3', text: 'Artifacts By Status'
    assert_selector 'h3', text: 'Top 10 Artifacts By Type'

    assert_selector 'h3', text: 'Top 10 Keywords'
    page.has_link? keyword, count: 1

    assert_selector 'h3', text: 'Tag Cloud'
    within '#tag-cloud' do
      assert_selector 'svg', count: 1
    end

    assert_selector 'h3', text: 'Search Logs for the 10 Most Recent Searches'
    page.has_button? 'View All Search Logs'
    page.has_link? 'Show Raw JSON', count: 1

    assert_selector 'h3', text: 'Search Counts for the Last 10 Days'
    assert_selector 'h3', text: 'Search Counts by Parameter for the Last 10 Days'
    assert_selector 'h3', text: 'Top 20 Search Terms for the Last 10 Days'

    assert_selector 'canvas', count: 7
  end

  test 'home is accessible' do
    sign_in create(:user)
    repository_1 = create_repository_with_artifacts(count: 2)
    repository_2 = create(:repository)
    create(:artifact, repository: repository_2, description: nil, keywords: [], artifact_status: 'draft')
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 1, update_count: 1, delete_count: 1)
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 0, update_count: 1, delete_count: 1)
    create(:search_log)
    visit '/home'
    assert_axe_accessible(page)
  end
end
