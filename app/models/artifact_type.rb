# frozen_string_literal: true

# A type of artifact, e.g. recommendation, tool, systematic review
class ArtifactType < ApplicationRecord
  has_many :artifact_type_associations, dependent: :destroy
  has_many :artifacts, through: :artifact_type_associations

  RECOMMENDATION = 'Recommendation'
  TOOL = 'Tool'

  def self.recommendation!
    where('name = ?', RECOMMENDATION).first!
  end

  def self.tool!
    where('name = ?', TOOL).first!
  end
end
