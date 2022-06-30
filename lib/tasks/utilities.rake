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

  desc 'Update SRDR links'
  task update_srdr_links: :environment do
    PaperTrail.request(enabled: false) do
      Artifact.joins(:repository).where(repositories: { alias: 'SRDR' }).each do |artifact|
        artifact.url = "#{Rails.configuration.srdr_base_url}public_data?id=#{artifact.remote_identifier}&type=project"
        artifact.save!
      end
    end
  end

  desc 'Remove obsolete USPSTF artifacts and version histories following change to ID format'
  task cleanup_uspstf: :environment do
    PaperTrail.request(enabled: false) do
      Repository.find_by(alias: 'USPSTF').artifacts.where(artifact_status: 'retracted').each do |artifact|
        if artifact.cedar_identifier.match?(/USPSTF-(TOOL|SR|GR)/)
          artifact.destroy
        end
      end
    end
    PaperTrail::Version.where(item_type: 'Artifact').where('item_id NOT IN (?)', Artifact.all.collect(&:id)).destroy_all
  end
end
