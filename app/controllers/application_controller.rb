# frozen_string_literal: true

# Catch and diplay authentication errors, redirect to home page after authentication succeeds
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: :internal_server_error
  end

  def after_sign_in_path_for(_resource)
    home_path
  end
end
