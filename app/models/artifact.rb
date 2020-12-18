class Artifact < ApplicationRecord
  belongs_to :repository
  has_many :artifact_type_associations
  has_many :artifact_types, through: :artifact_type_associations
end
