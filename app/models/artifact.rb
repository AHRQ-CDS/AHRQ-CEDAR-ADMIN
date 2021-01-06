# frozen_string_literal: true

# Represents a clinical evidence artifact stored in one of the repositories
# indexed by CEDAR.
class Artifact < ApplicationRecord
  belongs_to :repository

  enum artifact_type: {
    specific_recommendation: 'specific_recommendation',
    general_recommendation: 'general_recommendation',
    tool: 'tool'
  }

  def self.update_or_create!(remote_identifier, attributes)
    find_or_initialize_by(remote_identifier: remote_identifier).update!(attributes)
  end
end
