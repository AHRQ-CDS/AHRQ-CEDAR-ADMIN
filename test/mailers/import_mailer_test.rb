# frozen_string_literal: true

require 'test_helper'

class ImportMailerTest < ActionMailer::TestCase
  test 'failure' do
    import_run = ImportRun.new
    import_run.end_time = Time.current
    import_run.status = 'failure'
    import_run.error_message = 'This is the error message'
    create(:repository)
    import_run.repository = Repository.first
    import_run.id = 999
    email = ImportMailer.with(import_run: import_run).failure_email

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [Rails.configuration.cedar_to_email], email.to
    assert_equal [Rails.configuration.cedar_from_email], email.from
    assert email.subject.include? import_run.repository.alias
    assert email.subject.include? import_run.status.capitalize
    email_contents = email.text_part.body.to_s
    assert email_contents.include? import_run.repository.alias
    assert email_contents.include? import_run.status.capitalize
    assert email_contents.include? import_run.id.to_s
    email_contents = email.html_part.body.to_s
    assert email_contents.include? import_run.repository.alias
    assert email_contents.include? import_run.status.capitalize
    assert email_contents.include? import_run.id.to_s
  end

  test 'flagged' do
    import_run = ImportRun.new
    import_run.end_time = Time.current
    import_run.status = 'flagged'
    create(:repository)
    import_run.repository = Repository.first
    import_run.id = 999
    email = ImportMailer.with(import_run: import_run).flagged_email

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [Rails.configuration.cedar_to_email], email.to
    assert_equal [Rails.configuration.cedar_from_email], email.from
    assert email.subject.include? import_run.repository.alias
    assert email.subject.include? import_run.status.capitalize
    email_contents = email.text_part.body.to_s
    assert email_contents.include? import_run.repository.alias
    assert email_contents.include? import_run.status.capitalize
    assert email_contents.include? import_run.id.to_s
    email_contents = email.html_part.body.to_s
    assert email_contents.include? import_run.repository.alias
    assert email_contents.include? import_run.status.capitalize
    assert email_contents.include? import_run.id.to_s
  end
end
