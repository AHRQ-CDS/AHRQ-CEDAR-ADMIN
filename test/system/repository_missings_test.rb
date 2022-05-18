# frozen_string_literal: true

require 'application_system_test_case'

class RepositoryMissingsTest < ApplicationSystemTestCase
  setup do
    sign_in create(:user)
    @repository = create(:repository)
    create(:artifact, repository: @repository, description: 'Non-descript description', keywords: ['test'], artifact_status: 'active')
    create(:artifact, repository: @repository, description: nil, keywords: [], artifact_status: 'draft')
  end

  test 'repository_missing title functions as expected' do
    visit repository_missing_url(@repository) + '?missing=title'
    assert_selector 'h3', text: "#{@repository.name} Artifacts with missing title"
    assert_selector 'tbody>tr', count: 0
  end

  test 'repository_missing description functions as expected' do
    visit repository_missing_url(@repository) + '?missing=description'
    assert_selector 'h3', text: "#{@repository.name} Artifacts with missing description"
    assert_selector 'tbody>tr', count: 1
  end

  test 'repository_missing keywords functions as expected' do
    visit repository_missing_url(@repository) + '?missing=keyword'
    assert_selector 'h3', text: "#{@repository.name} Artifacts with missing keyword"
    assert_selector 'tbody>tr', count: 1
  end

  test 'repository_missing concepts functions as expected' do
    visit repository_missing_url(@repository) + '?missing=concept'
    assert_selector 'h3', text: "#{@repository.name} Artifacts with missing concept"
    assert_selector 'tbody>tr', count: 1
  end

  test 'repository_missing is accessible (generalizable)' do
    # All pages are just a table, no unique elements (only data differs) so just use concept
    visit repository_missing_url(@repository) + '?missing=concept'
    assert_axe_accessible(page)
  end
end
