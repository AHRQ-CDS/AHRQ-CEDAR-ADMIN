# frozen_string_literal: true

# Represents search statistics for an artifact stored in one of the repositories
# indexed by CEDAR. This model is based on a database view, not a regular table.
class ArtifactSearchStats < ApplicationRecord
  belongs_to :artifact

  def readonly?
    true
  end
end
