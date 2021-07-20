# frozen_string_literal: true

# Model for tracking the serach query at CEDAR API
class SearchParameterLog < ApplicationRecord
  belongs_to :search_log
end
