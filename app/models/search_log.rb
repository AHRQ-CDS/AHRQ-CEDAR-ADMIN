# frozen_string_literal: true

# Model for tracking the search query at CEDAR API
class SearchLog < ApplicationRecord
  has_many :search_parameter_logs, dependent: :destroy

  scope :last_ten_days, -> { where("start_time > ?", Time.now-10.days) }
  scope :last_searches, ->(num) { order('start_time DESC').limit(num) }

  paginates_per 50

end