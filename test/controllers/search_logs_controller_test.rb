# frozen_string_literal: true

require 'test_helper'

class SearchLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in create(:user)
    create(:search_log)
    get search_logs_url
    assert_response :success
    assert_equal 1, assigns(:search_logs).count
  end

  test 'should get index with ip' do
    sign_in create(:user)
    create(:search_log)
    get search_logs_url(ip: '192.168.1.1')
    assert_equal 1, assigns(:search_logs).count
    get search_logs_url(ip: '192.168.1.2')
    assert_equal 0, assigns(:search_logs).count
  end
end
