# frozen_string_literal: true

# Represents a clinical evidence artifact stored in one of the repositories
# indexed by CEDAR.
class ArtifactSearchStats < ApplicationRecord
  belongs_to :artifact

  def readonly?
    true
  end
end
