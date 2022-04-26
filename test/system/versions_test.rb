# frozen_string_literal: true

require 'application_system_test_case'

class VersionsTest < ApplicationSystemTestCase
  include ApplicationHelper

  setup do
    sign_in create(:user)
    with_versioning do
      repository = create(:repository)
      import_run = create(:import_run, repository: repository, start_time: Time.current,
                                       end_time: Time.current, total_count: 2, new_count: 1, update_count: 1)

      PaperTrail.request.controller_info = { import_run_id: import_run.id }
      @artifact = create(:artifact, repository: repository, description: 'Non-descript description', keywords: ['test'],
                                    artifact_status: 'draft')
      @version = @artifact.versions.last
    end
  end

  test 'version functions as expected' do
    visit paper_trail_version_url(@version)
    # Properties missing from test env left in but commented for awareness
    assert_selector 'h1', text: "#{@artifact.title} [#{format_datetime_with_tz(@version.created_at)}]"
    assert_selector 'h4', text: 'Id'
    # assert_selector 'h4', text: 'Url'
    assert_selector 'h4', text: 'Title'
    assert_selector 'h4', text: 'Created At'
    assert_selector 'h4', text: 'Description'
    assert_selector 'h4', text: 'Keyword Text'
    # assert_selector 'h4', text: 'Published On'
    assert_selector 'h4', text: 'Artifact Type'
    assert_selector 'h4', text: 'Repository'
    assert_selector 'h4', text: 'Artifact Status'
    # assert_selector 'h4', text: 'Cedar Identifier'
    assert_selector 'h4', text: 'Description Html'
    # assert_selector 'h4', text: 'Remote Identifier'
    assert_selector 'h4', text: 'Description Markdown'
  end

  test 'version is accessible' do
    visit paper_trail_version_url(@version)
    assert_axe_accessible(page)
  end
end
