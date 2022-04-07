# Configuration file for scheduling tasks using whenever (http://github.com/javan/whenever)

# Environment variables passed into Docker should be included in jobs run via crontab
ENV.each do |key, value|
  env key.to_sym, value
end

# Set the job template to use sh to work on alpine docker images
set :job_template, "/bin/sh -l -c ':job'"

# Custom rake task option that logs output
job_type :rake_log, "cd :path && :environment_variable=:environment :bundle_command rake :task > /proc/1/fd/1 2> /proc/1/fd/2"

# Schedule for imports: daily, scheduled to run by default during off-peak hours in the US
# Schedule for database backups: daily, scheduled to run 45 minutes after most recent import should have completed
# NOTE: This assumes the CEDAR server is set to UTC; 9am UTC is 4am EST and 1am PST

# We can specify the start time via an environment variable, otherwise we use a default of 9am (running on a server set to UTC)
import_time = Time.parse(ENV['IMPORT_TIME']) rescue Time.parse('9:00 am')
backup_time = import_time + 45.minutes

every 1.day, at: import_time.strftime('%I:%M %P') do
  rake_log "import:all"
end

every 1.day, at: backup_time.strftime('%I:%M %P') do
  rake_log "db:dump"
end
