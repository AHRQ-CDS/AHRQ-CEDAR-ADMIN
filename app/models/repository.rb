# frozen_string_literal: true

# Represents a repository indexed by CEDAR.
class Repository < ApplicationRecord
  has_many :artifacts, dependent: :destroy
  has_many :import_runs, dependent: :destroy
  has_many :stats, class_name: 'RepositoryStats', dependent: nil

  # When being displayed to a user, show the name
  def to_s
    name
  end
end
