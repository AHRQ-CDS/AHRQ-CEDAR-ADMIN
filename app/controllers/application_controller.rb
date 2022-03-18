# frozen_string_literal: true

# Catch and diplay authentication errors, redirect to home page after authentication succeeds
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  rescue_from Errno::ECONNREFUSED, ArgumentError do
    flash[:error] = 'Unable to reach LDAP authentication service. Please contact your admin.'
    redirect_to(request.referer || root_path)
  end

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    flash[:error] = exception.message
    redirect_to(request.referer || root_path)
  end

  def after_sign_in_path_for(_resource)
    home_path
  end
end
