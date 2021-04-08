# frozen_string_literal: true

# Model for tracking the results of indexing runs
# TODO: Naming... should it be ImportActivity
class IndexActivity < ApplicationRecord
  belongs_to :repository
  # Method for tracking an indexing run; yields a block within which indexing should take place
  def self.track(repository)
    index_activity = self.create(repository: repository, start_time: Time.now)
    try do
      # TODO: Note that this won't work if we ever delete... we don't expect to at this time
      before_count = repository.artifacts.count
      index_count = yield
      new_count = repository.artifacts.count - before_count
      update_count = index_count - new_count
      # TODO: figure out clear use of status
      # TODO: update count isn't acctually correct, we only care if the artifact actually changed
      # To do this, we should instrument update_or_create! to return some type of status (new, updated, unchanged)
      # Then, in the indexers, we can keep a hash of counts of the three statuses
      # Ideally, we'd find some way to instrument update_or_create! so that it doesn't pass things up...
      # Clunky, but pass a status-recording method into update_or_create!?
      # Less clunky: add an after_save to artifact that calls a method on index_activity, which updates something set up and blanked by this track method
      index_activity.update(end_time: Time.now, status: 'success', index_count: index_count, new_count: new_count, update_count: update_count)
    rescue => e
      # Track the failure and re-raise the error
      # TODO: We can use "retry" if indexing fails; number of retries should be configurable?
      index_activity.update(end_time: Time.now, status: 'failure', error_message: e.message)
      raise
    end
  end
end
