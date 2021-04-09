class CedarImporter
  def self.repository_name(name)
    @repository_name = name
  end

  def self.repository_home_page(home_page)
    @repository_home_page = home_page
  end

  def self.run
    raise 'Repository name not set' unless @repository_name
    raise 'Repository home page not set' unless @repository_home_page
    @repository = Repository.where(name: @repository_name).first_or_create!(home_page: @repository_home_page)
    @import_statistics = { total_count: 0, new_count: 0, update_count: 0 }
    import_run = ImportRun.create(repository: @repository, start_time: Time.now)
    try do
      download_and_update!
      import_run.update(@import_statistics.merge(end_time: Time.now, status: 'success'))
    rescue => e
      # Track the failure and re-raise the error
      # TODO: We can use "retry" if indexing fails; number of retries should be configurable?
      import_run.update(@@import_statistics.merge(end_time: Time.now, status: 'failure', error_message: e.message))
      raise
    ensure
      @import_statistics = nil
    end
  end

  # Update existing or create new entry for an artifact, tracking statistics
  def self.update_or_create_artifact!(cedar_identifier, attributes)
    # TODO: We may be able to enforce the correct call via some clever metaprogramming
    raise 'Repository not found; make sure the importer is being called via "run" and not directly via "download_and_update!"' unless @repository

    # Find existing or initialize new entry; this is roughly equivalent to find_or_initialize_by but broken
    # out so we can keep statistics on whether there are existing entries we're updating
    if artifact = Artifact.find_by(cedar_identifier: cedar_identifier)
      artifact.assign_attributes(attributes)
      changed = artifact.changed?
      artifact.save!
      @import_statistics[:update_count] += 1 if changed
    else
      artifact = create!(attributes.merge(cedar_identifier: cedar_identifier))
      @import_statistics[:update_count] += 1
    end
    @import_statistics[:total_count] += 1
  end

  # Convenience instance method that just calls the class method
  def update_or_create_artifact!(cedar_identifier, attributes)
    self.class.update_or_create_artifact!(cedar_identifier, attributes)
  end
end
