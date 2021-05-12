# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    repository_1 = create_repository_with_artifacts(count: 2)
    repository_2 = create(:repository)
    create(:artifact, repository: repository_2, description: nil, keywords: [], mesh_keywords: [], artifact_status: 'draft')
    create(:import_run, repository: repository_1, start_time: Time.current, end_time: Time.current, total_count: 2, new_count: 1, update_count: 1)
    get root_url
    assert_response :success
    assert_match 'CEDAR Statistics', @response.body
    assert_equal 3, assigns(:artifact_count)
    assert_equal 1, assigns(:artifact_count_missing_description)
    assert_equal 1, assigns(:artifact_count_missing_keywords)
    assert_equal 2, assigns(:artifacts_per_repository)&.[](repository_1)
    assert_equal 1, assigns(:artifacts_per_repository)&.[](repository_2)
    assert_equal 2, assigns(:artifacts_by_status)&.[]('active')
    assert_equal 1, assigns(:artifacts_by_status)&.[]('draft')
    assert_equal 1, assigns(:top_artifacts_by_type).length
    assert_equal 3, assigns(:top_artifacts_by_type)[0][1]
    assert_equal 8, assigns(:top_artifacts_per_keyword).length
    assert_equal 1, assigns(:import_runs).length
    assert_equal 1, assigns(:import_run_summaries).length
    assert_equal 2, assigns(:import_run_summaries).values.first.total_count
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
    create_repository_with_artifacts(count: 3)
    get keyword_counts_url
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 12, response.length
  end

  test 'should get import_run' do
    with_versioning do
      repository = create(:repository)
      import_run = create(:import_run, repository: repository, start_time: Time.current, end_time: Time.current, total_count: 2, new_count: 1, update_count: 1)
      PaperTrail.request.controller_info = { import_run_id: import_run.id }
      create(:artifact, repository: repository, description: nil, keywords: [], mesh_keywords: [], artifact_status: 'draft')
      get import_run_url(import_run)
      assert_response :success
      assert_equal import_run, assigns(:import_run)
      assert_equal 1, assigns(:versions).count
    end
  end

  test 'should get version' do
    with_versioning do
      repository = create(:repository)
      import_run = create(:import_run, repository: repository, start_time: Time.current, end_time: Time.current, total_count: 2, new_count: 1, update_count: 1)

      PaperTrail.request.controller_info = { import_run_id: import_run.id }
      artifact = create(:artifact, repository: repository, description: nil, keywords: [], mesh_keywords: [], artifact_status: 'draft')
      version = artifact.versions.last
      get paper_trail_version_url(artifact.versions.last)
      assert_response :success
      assert_equal version, assigns(:version)
      assert_equal 'create', assigns(:version).event

      PaperTrail.request.controller_info = { import_run_id: import_run.id }
      artifact.update(description: 'Description')
      version = artifact.versions.last
      get paper_trail_version_url(artifact.versions.last)
      assert_response :success
      assert_equal version, assigns(:version)
      assert_equal 'update', assigns(:version).event
      assert_equal 'Description', assigns(:version).object_changes['description'][1]
    end
  end
end
