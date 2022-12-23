# frozen_string_literal: true

class ImportMailerPreview < ActionMailer::Preview
  def failure_email
    import_run = ImportRun.new
    import_run.end_time = Time.current
    import_run.status = 'failure'
    import_run.error_message = 'This is the error message'
    import_run.repository = Repository.first
    import_run.id = 999
    ImportMailer.with(import_run: import_run).failure_email
  end

  def flagged_email
    import_run = ImportRun.new
    import_run.end_time = Time.current
    import_run.status = 'flagged'
    import_run.repository = Repository.first
    import_run.id = 999
    ImportMailer.with(import_run: import_run).flagged_email
  end
end
