# frozen_string_literal: true

# Represents a repository indexed by CEDAR.
class Repository < ApplicationRecord
  has_many :artifacts, dependent: :destroy

  has_many :import_runs, dependent: :destroy

  # When being displayed to a user, show the name
  def to_s
    name
  end
end
