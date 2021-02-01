# Based on some ideas from https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
namespace :db do

  desc "Dump the database to db/<APP_NAME>.dump"
  task :dump => :environment do
    with_config do |app, host, db, user|
      cmd = "pg_dump --host #{host} --username '#{user}' --verbose --clean --no-owner --no-acl --format=c #{db} > #{Rails.root}/db/#{app}.dump"
      puts cmd
      exec cmd
    end
  end

  desc "Restore the database from db/<APP_NAME>.dump"
  task :restore => :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    with_config do |app, host, db, user|
      cmd = "pg_restore --verbose --host #{host} --username '#{user}' --clean --no-owner --no-acl --dbname #{db} #{Rails.root}/db/#{app}.dump"
      puts cmd
      exec cmd
    end
  end

  private

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:host] || 'localhost',
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username]
  end

end
