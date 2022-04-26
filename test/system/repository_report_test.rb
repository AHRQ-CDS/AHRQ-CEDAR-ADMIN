# frozen_string_literal: true

require 'application_system_test_case'

class RepositoryReportTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    @repository = create_repository_with_artifacts(count: 2)
  end

  test 'repository functions as expected' do
    visit '/repository_report'
    assert_selector 'h1', text: 'Repository Report'
    assert_selector 'table', count: 1
    assert_selector 'td', text: @repository.name
  end

  test 'repository is accessible' do
    visit '/repository_report'
    assert_axe_accessible(page)
  end
end
