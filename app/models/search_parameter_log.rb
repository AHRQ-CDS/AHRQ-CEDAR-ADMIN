# frozen_string_literal: true

# Model for tracking the search parameters at CEDAR API
class SearchParameterLog < ApplicationRecord
  belongs_to :search_log
end
