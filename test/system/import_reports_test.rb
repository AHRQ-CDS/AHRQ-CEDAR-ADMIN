# frozen_string_literal: true

require 'application_system_test_case'

class ImportReportsTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    repository_1 = create_repository_with_artifacts(count: 2)
    repository_2 = create(:repository)
    create(:artifact, repository: repository_2, description: nil, keywords: [], artifact_status: 'draft')
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 1, update_count: 1, delete_count: 1, status: :flagged)
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current,
                        total_count: 2, new_count: 0, update_count: 1, delete_count: 1, status: :success)
  end

  test 'import_reports functions as expected' do
    # visits to ids w/i page scroll to elem in event of failure for screenshot
    visit '/import_reports'
    assert_selector 'h2', text: 'Import Reports'

    assert_selector '.float-heading', text: 'Flagged Import Runs: 1'
    assert_selector '.float-heading', text: 'Total Import Runs: 2'
    page.has_link? 'Repository 1', count: 3
  end

  test 'import_reports is accessible' do
    visit '/import_reports'
    assert_axe_accessible(page)
  end
end
