# frozen_string_literal: true

# Base class for all importers; supports set up of repository and tracking of each import
class CedarImporter
  def self.repository_name(name)
    @repository_name = name
  end

  def self.repository_home_page(home_page)
    @repository_home_page = home_page
  end

  def self.repository_fhir_id(fhir_id)
    @repository_fhir_id = fhir_id
  end

  # Set up the repository and cache it for access
  def self.repository
    raise 'Repository name not set' unless @repository_name

    raise 'Repository home page not set' unless @repository_home_page

    raise 'Repository FHIR ID not set' unless @repository_fhir_id

    @repository ||= Repository.where(name: @repository_name).first_or_create!(home_page: @repository_home_page, fhir_id: @repository_fhir_id)
  end

  # Convenience instance method that just calls the class method
  def repository
    self.class.repository
  end

  def self.run
    @import_statistics = { total_count: 0, new_count: 0, update_count: 0 }
    import_run = ImportRun.create(repository: repository, start_time: Time.current)
    try do
      download_and_update!
      # TODO: consider if we want to store statistics per-artifact rather than per-run
      import_run.update(@import_statistics.merge(end_time: Time.current, status: 'success'))
    rescue StandardError => e
      # Track the failure and re-raise the error
      # TODO: We can use "retry" if indexing fails; number of retries should be configurable?
      import_run.update(@import_statistics.merge(end_time: Time.current, status: 'failure', error_message: e.message))
      raise
    ensure
      @import_statistics = nil
    end
  end

  # Update existing or create new entry for an artifact, tracking statistics
  def self.update_or_create_artifact!(cedar_identifier, attributes)
    # TODO: We may be able to enforce download_and_update! not being called directly via some clever metaprogramming
    raise 'Import statistics not found; make sure the importer is being called via "run" and not directly via "download_and_update!"' unless @import_statistics

    # Find existing or initialize new entry; this is roughly equivalent to find_or_initialize_by but broken
    # out so we can keep statistics on whether there are existing entries we're updating
    artifact = Artifact.find_by(cedar_identifier: cedar_identifier)
    if artifact
      artifact.assign_attributes(attributes.merge(repository: repository))
      changed = artifact.changed?
      artifact.save!
      @import_statistics[:update_count] += 1 if changed
    else
      artifact = Artifact.create!(attributes.merge(cedar_identifier: cedar_identifier, repository: repository))
      @import_statistics[:new_count] += 1
    end
    @import_statistics[:total_count] += 1
    artifact
  end

  # Convenience instance method that just calls the class method
  def update_or_create_artifact!(cedar_identifier, attributes)
    self.class.update_or_create_artifact!(cedar_identifier, attributes)
  end
end
