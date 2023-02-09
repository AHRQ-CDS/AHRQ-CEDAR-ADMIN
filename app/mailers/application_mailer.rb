# frozen_string_literal: true

# Mailer for alerting admins of issues
class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.cedar_from_email
  layout 'mailer'
end
