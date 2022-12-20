# frozen_string_literal: true

require 'application_system_test_case'

class ImportRunsTest < ApplicationSystemTestCase
  include ApplicationHelper

  setup do
    sign_in create(:user)
    @repository = create_repository_with_artifacts(count: 2)
    @start = Time.current
    @import_run = create(:import_run, repository: @repository, start_time: @start,
                         end_time: Time.current, total_count: 2, new_count: 0, update_count: 0,
                         delete_count: 0, status: :success)
  end

  test 'import_run functions as expected' do
    visit import_run_url(@import_run)
    assert_selector 'h1', text: "Import Run (Success): #{@repository.name} [#{format_datetime_with_tz(@start)}]"
    assert_selector 'h4', text: 'Updated [0]'
    assert_selector 'h4', text: 'Added [0]'
    assert_selector 'h4', text: 'Deleted [0]'
    # Assert not shown when empty
    assert_select 'h4', { count: 0, text: 'Errors [0]' }
    assert_select 'h4', { count: 0, text: 'Warnings [0]' }
  end

  test 'import_run is accessible' do
    visit import_run_url(@import_run)
    assert_axe_accessible(page)
  end
end
