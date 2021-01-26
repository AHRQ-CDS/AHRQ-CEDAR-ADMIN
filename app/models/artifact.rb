# frozen_string_literal: true

# Represents a clinical evidence artifact stored in one of the repositories
# indexed by CEDAR.
class Artifact < ApplicationRecord
  belongs_to :repository

  def self.update_or_create!(cedar_identifier, attributes)
    find_or_initialize_by(cedar_identifier: cedar_identifier).update!(attributes)
  end
end
