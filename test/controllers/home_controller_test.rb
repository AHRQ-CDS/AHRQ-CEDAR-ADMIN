# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    repository1 = create_repository_with_artifacts(count: 2)
    repository2 = create(:repository)
    create(:artifact, repository: repository2, description: nil, keywords: [], mesh_keywords: [], artifact_status: 'draft')
    get root_url
    assert_response :success
    assert_match 'CEDAR Statistics', @response.body
    assert_equal 3, assigns(:artifact_count)
    assert_equal 1, assigns(:artifact_count_missing_description)
    assert_equal 1, assigns(:artifact_count_missing_keywords)
    assert_equal 2, assigns(:artifacts_per_repository)&.[](repository1)
    assert_equal 1, assigns(:artifacts_per_repository)&.[](repository2)
    assert_equal 2, assigns(:artifacts_by_status)&.[]('active')
    assert_equal 1, assigns(:artifacts_by_status)&.[]('draft')
    assert_equal 1, assigns(:top_artifacts_by_type).length
    assert_equal 3, assigns(:top_artifacts_by_type)[0][1]
    assert_equal 8, assigns(:top_artifacts_per_keyword).length
  end

  test 'should get repository' do
    repository = create_repository_with_artifacts(count: 2)
    create(:artifact, repository: repository, description: nil, keywords: [], mesh_keywords: [], artifact_status: 'draft')
    get repository_url(repository)
    assert_response :success
    assert_match repository.name, @response.body
    assert_equal repository, assigns(:repository)
    assert_equal 3, assigns(:artifact_count)
    assert_equal 1, assigns(:artifact_count_missing_description)
    assert_equal 1, assigns(:artifact_count_missing_keywords)
    assert_equal 2, assigns(:artifacts_by_status)&.[]('active')
    assert_equal 1, assigns(:artifacts_by_status)&.[]('draft')
    assert_equal 3, assigns(:artifacts_by_type)&.[]('test')
    assert_equal 8, assigns(:top_artifacts_per_keyword).length
  end

  test 'should get artifact' do
    artifact = create :artifact
    get artifact_url(artifact)
    assert_response :success
    assert_match artifact.title, @response.body
    assert_equal artifact, assigns(:artifact)
  end

  test 'should get keyword' do
    repository = create_repository_with_artifacts(count: 1)
    keyword = repository.artifacts.first.keywords.first
    get keyword_url(keyword)
    assert_response :success
    assert_match keyword, @response.body
    assert_equal 1, assigns(:artifacts).count
    assert_equal 1, assigns(:artifacts_per_repository)&.[](repository)
    assert_equal 3, assigns(:top_artifacts_per_keyword).length
  end

  test 'should get keyword_counts' do
    repository = create_repository_with_artifacts(count: 3)
    get keyword_counts_url
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 12, response.length
  end
end
