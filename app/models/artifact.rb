# frozen_string_literal: true

# Represents a clinical evidence artifact stored in one of the repositories
# indexed by CEDAR.
class Artifact < ApplicationRecord
  belongs_to :repository
  has_many :artifact_type_associations, dependent: :destroy
  has_many :artifact_types, through: :artifact_type_associations
  
  def self.update_or_create!(remote_identifier, attributes)
    a = find_or_initialize_by(
      remote_identifier: remote_identifier
    )
    a.update!(attributes)
  end
end
