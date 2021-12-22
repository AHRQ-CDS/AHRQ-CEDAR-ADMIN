require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class AuthBypass < Authenticatable
      def valid?
        Rails.configuration.ldap_auth_bypass
      end

      def authenticate!
        if params[:user] && params[:user][:username]
          user = User.find_or_create_by(username: params[:user][:username])
          success!(user)
        else
          fail
        end
      end
    end
  end
end

Warden::Strategies.add(:auth_bypass, Devise::Strategies::AuthBypass)
