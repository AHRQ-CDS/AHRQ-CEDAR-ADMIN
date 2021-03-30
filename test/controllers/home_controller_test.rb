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
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Autism' }, 'Expected keyword "Autism" is not present'
    assert assigns(:top_artifacts_per_keyword)&.detect { |k, _v| k == 'Neurology' }, 'Expected keyword "Neurology" is not present'
  end
end
