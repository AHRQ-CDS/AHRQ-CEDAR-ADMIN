# frozen_string_literal: true

namespace :utilities do
  REPOSITORY_ALIAS_TO_NAME = {
    'USPSTF' => 'United States Preventive Services Taskforce',
    'CDS Connect' => 'CDS Connect',
    'EHC' => 'Effective Health Care Program',
    'EPC' => 'Evidence-based Practice Center',
    'SRDR' => 'Systematic Review Data Repository',
    'NGC' => 'National Guideline Clearinghouse',
  }.freeze

  desc 'Populate repository names'
  task populate_repository_names: :environment do
    abort("Missing required migration! Run bundle exec rake db:migrate") unless Repository.column_names.include? 'alias'

    REPOSITORY_ALIAS_TO_NAME.each do |repository_alias, name|
      repository = Repository.find_by(alias: repository_alias)

      if repository and repository.name.nil?
        repository.name = name
        repository.save!
      end
    end
  end
end