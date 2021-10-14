# Based on some ideas from https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
namespace :db do

  desc "Dump the database to datafiles/<APP_NAME>_<DATE>.dump"
  task :dump => :environment do
    with_config do |app, date, host, db, user|
      cmd = "pg_dump --host #{host} --username '#{user}' --verbose --clean --no-owner --no-acl --format=c #{db} > #{Rails.root}/datafiles/#{app}_#{date}.dump"
      puts cmd
      exec cmd
    end
  end

  desc "Restore the database from datafiles/<APP_NAME>_<DATE>.dump using the current date or a date from the DATE_STRING environment variable in the format YYYY_MM_DD"
  task :restore => :environment do
    with_config do |app, date, host, db, user|
      # Use environment variable for the date if provided otherwise use the current date from the config
      date = ENV.fetch('DATE_STRING') { date }
      # Make sure the file is present before dropping the existing database
      filename = "#{Rails.root}/datafiles/#{app}_#{date}.dump"
      raise "Database backup file '#{filename}' not found" unless File.exists?(filename)
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      cmd = "pg_restore --verbose --host #{host} --username '#{user}' --clean --no-owner --no-acl --dbname #{db} #{filename}"
      puts cmd
      exec cmd
    end
  end

  private

  def with_config
    yield Rails.application.class.module_parent_name.underscore,
          Date.today.strftime("%Y_%m_%d"),
          ActiveRecord::Base.connection_config[:host] || 'localhost',
          ActiveRecord::Base.connection_config[:database],
          ActiveRecord::Base.connection_config[:username]
  end

end
