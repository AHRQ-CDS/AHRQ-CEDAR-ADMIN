# frozen_string_literal: true

# Model for tracking the search query at CEDAR API
class SearchLog < ApplicationRecord
  scope :last_ten_days, -> { where('start_time > ?', 10.days.ago) }
  scope :last_searches, ->(num) { order('start_time DESC').limit(num) }

  paginates_per 50
end
