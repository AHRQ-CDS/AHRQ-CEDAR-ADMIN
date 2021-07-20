# frozen_string_literal: true

# Model for tracking the serach query at CEDAR API
class SearchLog < ApplicationRecord
  has_many :search_parameter_logs, dependent: :destroy
end
