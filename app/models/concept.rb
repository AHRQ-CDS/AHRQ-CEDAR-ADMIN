# frozen_string_literal: true

# Represents a canonical concept and it's synonyms.
class Concept < ApplicationRecord
  def synonyms_text=(terms)
    super(terms)
    self.synonyms_psql = terms.map { |t| t.split(/[, ]+/).join('<->') }
  end
end
