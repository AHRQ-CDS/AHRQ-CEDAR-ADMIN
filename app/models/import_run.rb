# frozen_string_literal: true

# Model for tracking the results of indexing runs
class ImportRun < ApplicationRecord
  belongs_to :repository

  enum status: { success: 'success', failure: 'failure' }

  # Method for tracking an indexing run; yields a block within which indexing should take place
  def self.track(repository)
    # TODO: Add note re: multi-threaded
    @@import_statistics = { total_count: 0, new_count: 0, update_count: 0 }
    import_run = self.create(repository: repository, start_time: Time.now)
    try do
      yield
      import_run.update(@@import_statistics.merge(end_time: Time.now, status: 'success'))
    rescue => e
      # Track the failure and re-raise the error
      # TODO: We can use "retry" if indexing fails; number of retries should be configurable?
      import_run.update(@@import_statistics.merge(end_time: Time.now, status: 'failure', error_message: e.message))
      raise
    ensure
      @@import_statistics = nil
    end
  end

  # Track the creation of a new artifact during a tracking run
  def self.track_new
    raise "Track method called when not tracking" unless @@import_statistics
    @@import_statistics[:total_count] += 1
    @@import_statistics[:new_count] += 1
  end

  # Track the update of an existing artifact during a tracking run
  def self.track_updated
    raise "Track method called when not tracking" unless @@import_statistics
    @@import_statistics[:total_count] += 1
    @@import_statistics[:update_count] += 1
  end

  # Track any unchanged artifacts during a tracking run
  def self.track_unchanged
    raise "Track method called when not tracking" unless @@import_statistics
    @@import_statistics[:total_count] += 1
  end
end
