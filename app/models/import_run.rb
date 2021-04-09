# frozen_string_literal: true

# Model for tracking the results of indexing runs
class ImportRun < ApplicationRecord
  belongs_to :repository

  enum status: { success: 'success', failure: 'failure' }
end
