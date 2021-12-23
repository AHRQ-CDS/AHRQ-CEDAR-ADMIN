# Based on some ideas from https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
namespace :db do

  LOCATION = File.join(Rails.root, 'datafiles')

  desc "Dump the database to datafiles/<APP_NAME>_<DATETIME>.dump"
  task :dump => :environment do
    with_config do |app, host, db, user|
      datetime = DateTime.now.strftime("%Y_%m_%d__%H_%M_%S")
      filename = File.join(LOCATION, "#{app}_#{datetime}.dump")
      cmd = "pg_dump --host #{host} --username '#{user}' --verbose --clean --no-owner --no-acl --format=c #{db} > #{filename}"
      puts cmd
      exec cmd
    end
  end

  desc "Restore the database from datafiles/<APP_NAME>_<DATETIME>.dump using the date from the DATETIME environment variable"
  task :restore => :environment do
    with_config do |app, host, db, user|
      # Use environment variable for the date (just look at the files to find a valid one)
      datetime = ENV['DATETIME']
      raise "Datetime must be provided using the DATATIME environment variable (YY_MM_DD__HH_MM_SS)" unless datetime
      filename = File.join(LOCATION, "#{app}_#{datetime}.dump")
      # Make sure the file is present before dropping the existing database
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
          ActiveRecord::Base.connection_config[:host] || 'localhost',
          ActiveRecord::Base.connection_config[:database],
          ActiveRecord::Base.connection_config[:username]
  end

end
