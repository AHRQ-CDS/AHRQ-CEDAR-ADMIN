# frozen_string_literal: true

require_relative './application_record'

# Represents a repository indexed by CEDAR.
class Repository < ApplicationRecord
  USPSTF = 'USPSTF'

  def self.uspstf!
    where('name = ?', USPSTF).first!
  end
end
