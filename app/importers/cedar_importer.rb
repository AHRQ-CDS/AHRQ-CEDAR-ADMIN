# frozen_string_literal: true

# Base class for all importers; supports set up of repository and tracking of each import
class CedarImporter
  def self.repository_name(repository_name)
    @repository_name = repository_name
  end

  def self.repository_alias(repository_alias)
    @repository_alias = repository_alias
  end

  def self.repository_home_page(repository_home_page)
    @repository_home_page = repository_home_page
  end

  # Set up the repository and cache it for access
  def self.repository
    raise 'Repository name not set' unless @repository_name

    raise 'Repository home page not set' unless @repository_home_page

    # Don't cache this value since it causes problems when running tests if the same importer is used
    # in different test files
    Repository.where(name: @repository_name).first_or_create!(
      alias: @repository_alias,
      home_page: @repository_home_page,
      fhir_id: @repository_alias.downcase.gsub(/\W+/, '-')
    )
  end

  # Convenience instance method that just calls the class method
  def repository
    self.class.repository
  end

  def self.run
    unless repository.enabled
      Rails.logger.warn "Skipping #{repository.alias} import, importer is disabled"
      return false
    end

    # Track import statistics and set up an import run to store them
    # TODO: It may be possible to just count the paper trail updates, additions, and deletions at the end instead
    @import_statistics = {
      total_count: 0,
      new_count: 0,
      update_count: 0,
      delete_count: 0,
      error_msgs: [],
      warning_msgs: []
    }
    # Start a transaction to so that the import completes atomically, this ensures that API
    # clients won't see partial, potentially inconsistent, updates during import runs.
    ImportRun.transaction do
      import_run = ImportRun.create(repository: repository, start_time: Time.current)

      # When we track any changes to artifacts we want to associate the change with the appropriate import run
      PaperTrail.request.controller_info = { import_run_id: import_run.id }

      # Track artifacts we update or create so that all others are marked for deletion
      @imported_artifact_ids = []
      changed_count = 0
      original_count = 0

      try do
        # Run the individually defined importer
        download_and_update!

        # Mark any entries that were not found in the completed index run as deleted
        deleted_artifacts = repository.artifacts.where.not(id: @imported_artifact_ids).where.not(artifact_status: 'retracted').all
        @import_statistics[:delete_count] = deleted_artifacts.length
        deleted_artifacts.each do |artifact|
          artifact.artifact_status = 'retracted'
          artifact.paper_trail_event = 'retract'
          artifact.save!
        end

        # TODO: consider if we want to store statistics per-artifact rather than per-run
        import_run.update(@import_statistics.merge(end_time: Time.current, status: 'success'))
      rescue StandardError => e
        # Log the failure and abort the import run for this importer
        # TODO: We can use "retry" if indexing fails; number of retries should be configurable?
        import_run.update(@import_statistics.merge(end_time: Time.current, status: 'failure', error_message: e.message))
        ImportMailer.with(import_run: import_run).failure_email.deliver_now
      ensure
        changed_count = @import_statistics[:update_count] + @import_statistics[:delete_count]
        original_count = @import_statistics[:total_count] - @import_statistics[:new_count]
        @import_statistics = nil
      end

      # If too much changed for this import we add new versions of the artifacts to rollback updates
      # and deletions. Also mark the import as suspect and in need of admin review and disable the
      # importer
      suppress_large_change_detection = ActiveModel::Type::Boolean.new.cast(ENV['suppress_large_change_detection'])
      if !suppress_large_change_detection && original_count.positive? && changed_count * 100 / original_count > 10 # 10% change threshold
        # loop over the items that changed on this import run
        import_run.versions.map(&:item).each do |artifact|
          if artifact.paper_trail.previous_version.nil?
            # new artifact
            artifact.artifact_status = :suppressed
          else
            # changed artifact
            artifact = artifact.paper_trail.previous_version
          end
          artifact.paper_trail_event = 'suppress'
          artifact.save!
        end
        import_run.update status: :flagged
        repository.update enabled: false
        ImportMailer.with(import_run: import_run).flagged_email.deliver_now
      end
    end
    true
  end

  # Update existing or create new entry for an artifact, tracking statistics
  def self.update_or_create_artifact!(cedar_identifier, attributes)
    # TODO: We may be able to enforce download_and_update! not being called directly via some clever metaprogramming
    raise 'Import statistics not found; make sure the importer is being called via "run" and not directly via "download_and_update!"' unless @import_statistics

    # Find existing or initialize new entry; this is roughly equivalent to find_or_initialize_by but broken
    # out so we can keep statistics on whether there are existing entries we're updating
    @import_statistics[:total_count] += 1
    artifact = Artifact.find_by(cedar_identifier: cedar_identifier)
    @import_statistics[:warning_msgs].concat attributes[:warnings] if attributes[:warnings].present?
    attributes.delete(:warnings)
    normalize_attribute_values(attributes)
    if attributes[:error].present?
      # if a (presumably transient) error occured while processing an artifact we don't change an
      # existing artifact (except to possibly mark it as retracted) or create a new one
      error_message = attributes[:error]
      # set the artifact to retracted if its last successful update is two weeks ago
      if artifact.present? && artifact.artifact_status != 'retracted' && artifact.updated_at.to_datetime < DateTime.now - 14.days
        artifact.artifact_status = 'retracted'
        artifact.paper_trail_event = 'retract'
        artifact.save!
        error_message += ' (14 days since update, marking as retracted)'
        @import_statistics[:update_count] += 1
      end
      @import_statistics[:error_msgs] << error_message
      attributes.delete(:error)
    elsif artifact.present?
      # Set all description fields to nil so any changed description will be propagrated to all three
      # TODO: Temporarily avoid removing the description if it's not in the source repository
      if attributes[:description] || attributes[:description_html] || attributes[:description_markdown]
        artifact.assign_attributes(description: nil, description_html: nil, description_markdown: nil)
      end
      # Set the new attribute values
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

  def self.normalize_attribute_values(attributes)
    text_fields = %i[title description description_html description_markdown url doi artifact_type artifact_status
                     quality_of_evidence_statement strength_of_recommendation_statement]
    text_fields.each do |field|
      # Strip whitespace if the attribute has a value. Don't use present? or blank? since these ignore whitespace
      attributes[field] = attributes[field].strip unless attributes[field].nil?
    end
  end
end
