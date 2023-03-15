# frozen_string_literal: true

require 'test_helper'

class SearchStatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def create_search_log
    start_time = Time.zone.now
    end_time = start_time + 1.second
    create(:search_log,
           search_params: { '_content' => 'statin', 'artifact-current-state' => 'active' },
           count: 10,
           total: 27,
           client_ip: '192.168.1.1',
           start_time: start_time,
           end_time: end_time,
           returned_artifact_ids: [2565, 2989, 2943, 3086, 3087, 2945, 2944, 2306, 508, 3036])
  end

  test 'should get index' do
    sign_in create(:user)
    create_search_log
    get search_stats_url
    assert_response :success
    assert_equal 1, assigns(:search_count)
    assert_equal 0, assigns(:searches_per_day)
    assert_equal 1.0, assigns(:average_time)
    assert_equal 1, assigns(:ip_addresses).count
  end

  test 'should get index with date range' do
    sign_in create(:user)
    create_search_log
    get search_stats_url(start_date: Time.zone.today - 10.days, end_date: Time.zone.today - 5.days)
    assert_response :success
    assert_equal 0, assigns(:search_count)
    assert_equal 0, assigns(:searches_per_day)
    assert_nil assigns(:average_time)
    assert_equal 0, assigns(:ip_addresses).count
  end

  test 'should get index with ip exclusion' do
    sign_in create(:user)
    create_search_log
    get search_stats_url(exclude_ips: '192.168.1.1')
    assert_response :success
    assert_equal 0, assigns(:search_count)
    assert_equal 0, assigns(:searches_per_day)
    assert_nil assigns(:average_time)
    assert_equal 0, assigns(:ip_addresses).count
  end
end
