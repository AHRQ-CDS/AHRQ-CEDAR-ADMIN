# Configuration file for scheduling tasks using whenever (http://github.com/javan/whenever)

# Environment variables passed into Docker should be included in jobs run via crontab
ENV.each do |key, value|
  env key.to_sym, value
end

# Set the job template to use sh to work on alpine docker images
set :job_template, "/bin/sh -l -c ':job'"

# Custom rake task option that logs output
job_type :rake_log, "cd :path && :environment_variable=:environment :bundle_command rake :task > /proc/1/fd/1 2> /proc/1/fd/2"

# Schedule for imports: daily, scheduled to run during off-peak hours in the US
# NOTE: This assumes the CEDAR server is set to UTC; 9am UTC is 4am EST and 1am PST
#every 1.day, at: '9:00 am' do
#  rake_log "import:all"
#end

# TODO: TEMPORARILY SETTING TO HOURLY IMPORTS FOR DEBUGGING SOME IMPORTER ODDNESS
every 1.hour do
  rake_log "import:all"
end

# Schedule for database backups: daily, scheduled to run when the most recent import should have completed
# NOTE: This assumes the CEDAR server is set to UTC; 9:40am UTC is 4:40am EST and 1:40am PST
every 1.day, at: '9:40 am' do
  rake_log "db:dump"
end
