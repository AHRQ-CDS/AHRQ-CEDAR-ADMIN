# frozen_string_literal: true

# Sends emails related to importer activity
class ImportMailer < ApplicationMailer
  def failure_email
    @import_run = params[:import_run]
    @url = import_run_url @import_run
    mail(to: Rails.configuration.cedar_to_email,
         subject: "CEDAR #{@import_run.repository.alias} Importer #{@import_run.status.capitalize}")
  end

  def flagged_email
    @import_run = params[:import_run]
    @url = import_run_url @import_run
    mail(to: Rails.configuration.cedar_to_email,
         subject: "CEDAR #{@import_run.repository.alias} Import #{@import_run.status.capitalize}")
  end
end
