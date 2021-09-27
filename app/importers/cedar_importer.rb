# frozen_string_literal: true

# Base class for all importers; supports set up of repository and tracking of each import
class CedarImporter
  def self.repository_name(name)
    @repository_name = name
  end

  def self.repository_home_page(home_page)
    @repository_home_page = home_page
  end

  # Set up the repository and cache it for access
  def self.repository
    raise 'Repository name not set' unless @repository_name

    raise 'Repository home page not set' unless @repository_home_page

    # Don't cache this value since it causes problems when running tests if the same importer is used
    # in different test files
    Repository.where(name: @repository_name).first_or_create!(
      home_page: @repository_home_page,
      fhir_id: @repository_name.downcase.gsub(/\W+/, '-')
    )
  end

  # Convenience instance method that just calls the class method
  def repository
    self.class.repository
  end

  def self.run
    # Track import statistics and set up an import run to store them
    # TODO: It may be possible to just count the paper trail updates, additions, and deletions at the end instead
    @import_statistics = { total_count: 0, new_count: 0, update_count: 0, delete_count: 0, error_count: 0 }
    import_run = ImportRun.create(repository: repository, start_time: Time.current)

    # When we track any changes to artifacts we want to associate the change with the appropriate import run
    PaperTrail.request.controller_info = { import_run_id: import_run.id }

    # Track artifacts we update or create so that all others are marked for deletion
    @imported_artifact_ids = []

    try do
      # Run the individually defined importer
      download_and_update!

      # Remove any entries that were not found in the completed index run; this is needed because e.g. USPSTF
      # JSON identifiers are not persistent so this step is needed to clean up the database
      # TODO: Just mark these as deleted? By adding an artifact status?
      deleted_artifacts = repository.artifacts.where.not(id: @imported_artifact_ids).destroy_all
      @import_statistics[:delete_count] = deleted_artifacts.length

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
    @import_statistics[:total_count] += 1
    artifact = Artifact.find_by(cedar_identifier: cedar_identifier)
    if attributes[:error].present?
      # if a (presumably transient) error occured while processing an artifact we don't change an
      # existing artifact or create a new one
      @import_statistics[:error_count] += 1
    elsif artifact.present?
      artifact.assign_attributes(attributes.merge(repository: repository))
      changed = artifact.changed?
      artifact.save!
      @import_statistics[:update_count] += 1 if changed
    else
      artifact = Artifact.create!(attributes.merge(cedar_identifier: cedar_identifier, repository: repository))
      @import_statistics[:new_count] += 1
    end
    @imported_artifact_ids << artifact.id unless artifact.nil?
    artifact
  end

  # Convenience instance method that just calls the class method
  def update_or_create_artifact!(cedar_identifier, attributes)
    self.class.update_or_create_artifact!(cedar_identifier, attributes)
  end
end
