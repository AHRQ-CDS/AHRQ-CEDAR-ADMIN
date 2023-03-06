# frozen_string_literal: true

# Represents statistics for one of the artifact types contained by one of the repositories indexed
# by CEDAR. This model is based on a database view, not a regular table.
class RepositoryStats < ApplicationRecord
  belongs_to :repository

  def readonly?
    true
  end
end
