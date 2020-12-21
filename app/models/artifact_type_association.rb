# frozen_string_literal: true

# Represents the many-many associations between artifacts and types
class ArtifactTypeAssociation < ApplicationRecord
  belongs_to :artifact
  belongs_to :artifact_type
end
