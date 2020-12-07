# frozen_string_literal: true

# Abstract base class for application ActiveRecord use
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
