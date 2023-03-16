# frozen_string_literal: true

require 'test_helper'

class IpLookupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in create(:user)
    stub_request(:get, 'https://rdap.org/ip/127.0.0.1').to_return(status: 200, body: { name: 'ORGANIZATION' }.to_json)
    get ip_lookups_url(ip: '127.0.0.1')
    assert_response :success
    assert_equal 'ORGANIZATION', assigns(:name)
  end
end
