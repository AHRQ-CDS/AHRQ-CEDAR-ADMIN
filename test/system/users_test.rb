# frozen_string_literal: true

require 'application_system_test_case'

class UsersSystemTest < ApplicationSystemTestCase
  test 'sign_in functions as expected' do
    visit '/sign_in'
    assert_selector 'h2', text: 'Please log in'
    fill_in 'Username', with: 'admin'
    fill_in 'Password', with: 'cedar'
    click_on 'Log in'
  end

  test 'sign_in is accessible' do
    visit '/sign_in'
    assert_axe_accessible(page)
  end

  test 'sign_out functions as expected' do
    sign_in create(:user)
    visit '/users/sign_out'
    assert_selector '.alert', text: 'Signed out successfully.'
  end

  test 'sign_out is accessible' do
    sign_in create(:user)
    visit '/users/sign_out'
    assert_axe_accessible(page)
  end
end
