# frozen_string_literal: true

# Represents a canonical concept and it's synonyms.
class Concept < ApplicationRecord
  has_and_belongs_to_many :artifacts

  def synonyms_text=(terms)
    terms = terms.map { |t| t.gsub(/\s&\s/, ' ') }
    super(terms)
    self.synonyms_psql = terms.map { |t| t.gsub(/\s&\s/, ' ').delete('&').split(/[, ():']+/).reject(&:empty?).join('<->') }.uniq
  end
end
