# frozen_string_literal: true

# Represents a repository indexed by CEDAR.
class Repository < ApplicationRecord
  has_many :artifacts, dependent: :destroy
end
