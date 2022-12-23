# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.cedar_from_email
  layout 'mailer'
end
