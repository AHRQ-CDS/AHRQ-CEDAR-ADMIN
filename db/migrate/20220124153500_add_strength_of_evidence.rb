# frozen_string_literal: true

class AddStrengthOfEvidence < ActiveRecord::Migration[6.0]
  def change
    add_column :artifacts, :strength_of_recommendation_statement, :string
    add_column :artifacts, :strength_of_recommendation_score, :integer, :default => 0
    add_column :artifacts, :quality_of_evidence_statement, :string
    add_column :artifacts, :quality_of_evidence_score, :integer, :default => 0
  end
end
