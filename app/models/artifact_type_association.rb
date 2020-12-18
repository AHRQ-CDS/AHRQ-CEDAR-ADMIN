class ArtifactTypeAssociation < ApplicationRecord
  belongs_to :artifact
  belongs_to :artifact_type
end
