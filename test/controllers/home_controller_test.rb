# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  test 'should get index' do
    get root_url
    assert_response :success
    assert_match 'CEDAR Statistics', @response.body
    assert_equal 3, assigns(:artifact_count)
    assert_equal 1, assigns(:artifact_count_missing_description)
    assert_equal 1, assigns(:artifact_count_missing_keywords)
    assert_equal 1, assigns(:artifacts_per_repository)&.[](Repository.where(name: 'CDS Connect').first)
    assert_equal 2, assigns(:artifacts_per_repository)&.[](Repository.where(name: 'USPSTF').first)
    assert_equal 2, assigns(:artifacts_by_status)&.[]('active')
    assert_equal 1, assigns(:artifacts_by_status)&.[]('draft')
    assert assigns(:top_artifacts_by_type)&.detect { |k, v| k == 'Multimodal' && v == 1 }, 'Expected type "Multimodal" is not present'
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Autism' }, 'Expected keyword "Autism" is not present'
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Neurology' }, 'Expected keyword "Neurology" is not present'
  end

  test 'should get repository' do
    repository = Repository.first
    get repository_url(repository)
    assert_response :success
    assert_match repository.name, @response.body
    assert_equal repository, assigns(:repository)
    assert_equal 2, assigns(:artifact_count)
    assert_equal 0, assigns(:artifact_count_missing_description)
    assert_equal 1, assigns(:artifact_count_missing_keywords)
    assert_equal 2, assigns(:artifacts_by_status)&.[]('active')
    assert_nil assigns(:artifacts_by_status)&.[]('draft')
    assert_equal 2, assigns(:artifacts_by_type)&.[]('General Recommendation')
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Autism' }, 'Expected keyword "Autism" is not present'
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Spectrum' }, 'Expected keyword "Spectrum" is not present'
  end

  test 'should get artifact' do
    artifact = Artifact.first
    get artifact_url(artifact)
    assert_response :success
    assert_match artifact.title, @response.body
    assert_equal artifact, assigns(:artifact)
  end

  test 'should get keyword' do
    get keyword_url('Autism')
    assert_response :success
    assert_match 'Autism', @response.body
    assert_equal 1, assigns(:artifacts).count
    assert_equal 1, assigns(:artifacts_per_repository)&.[](Repository.where(name: 'USPSTF').first)
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Spectrum' }, 'Expected keyword "Spectrum" is not present'
  end

  test 'should get keyword_counts' do
    get keyword_counts_url
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 6, response.length
    assert response.detect { |r| r['text'] == 'Autism' && r['size'] == 120 }, 'Expected keyword "Autism" is not present'
  end
end
