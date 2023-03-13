# frozen_string_literal: true

require 'test_helper'

class SearchLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in create(:user)
    create(:search_log,
           search_params: { '_content' => 'statin', 'artifact-current-state' => 'active' },
           count: 10,
           total: 27,
           client_ip: '192.168.1.1',
           start_time: Time.zone.now,
           end_time: 1.second.from_now,
           returned_artifact_ids: [2565, 2989, 2943, 3086, 3087, 2945, 2944, 2306, 508, 3036])
    get search_logs_url
    assert_response :success
    assert_equal 1, assigns(:search_logs).count
  end

  test 'should get index with ip' do
    sign_in create(:user)
    create(:search_log,
           search_params: { '_content' => 'statin', 'artifact-current-state' => 'active' },
           count: 10,
           total: 27,
           client_ip: '192.168.1.1',
           start_time: Time.zone.now,
           end_time: 1.second.from_now,
           returned_artifact_ids: [2565, 2989, 2943, 3086, 3087, 2945, 2944, 2306, 508, 3036])
    get search_logs_url(ip: '192.168.1.1')
    assert_equal 1, assigns(:search_logs).count
    get search_logs_url(ip: '192.168.1.2')
    assert_equal 0, assigns(:search_logs).count
  end
end
