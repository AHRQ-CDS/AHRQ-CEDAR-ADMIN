# frozen_string_literal: true

# Model for tracking the results of indexing runs
class ImportRun < ApplicationRecord
  belongs_to :repository
  has_many :versions, class_name: 'PaperTrail::Version', dependent: :nullify

  enum status: { success: 'success', failure: 'failure', suppressed: 'suppressed',
                 flagged: 'flagged', reviewed: 'reviewed' }
end
