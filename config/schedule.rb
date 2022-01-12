# Configuration file for scheduling tasks using whenever (http://github.com/javan/whenever)

# Environment variables passed into Docker should be included in jobs run via crontab
ENV.each do |key, value|
  env key.to_sym, value
end

# Set the job template to use sh to work on alpine docker images
set :job_template, "/bin/sh -l -c ':job'"

# Custom rake task option that logs output
job_type :rake_log, "cd :path && :environment_variable=:environment :bundle_command rake :task > /proc/1/fd/1 2> /proc/1/fd/2"

every 1.day, at: '4:30 am' do
  # TODO: This gives us an initial backup schedule that aligns with the biggest database change; if we move to
  # weekly imports we should probably add a separate task for daily backups
  rake_log "import:all db:dump"
end
