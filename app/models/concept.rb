# frozen_string_literal: true

# Represents a canonical concept and it's synonyms.
class Concept < ApplicationRecord
  has_and_belongs_to_many :artifacts

  def synonyms_text=(terms)
    super(terms.clone) # keep all of the synonyms_text

    # generate minimal set of synonyms_psql by removing terms with
    # subsets (e.g. 'foo bar' is a subset of 'foo bar, baz') and terms with
    # only punctuation differences (e.g. 'foo bar' and 'foo, bar' are equivalent)
    terms.each do |subset|
      terms.delete_if { |term| subset? term, subset }
    end
    self.synonyms_psql = stemmed_psql(terms)
  end

  def subset?(phrase, subset)
    return false if phrase == subset # duplicates will be handle via the uniq method

    phrase_words = words_of phrase
    subset_words = words_of subset

    start_of_subset_in_phrase = phrase_words.index(subset_words[0])
    return if start_of_subset_in_phrase.nil?

    phrase_subset = phrase_words[start_of_subset_in_phrase, subset_words.length]

    phrase_subset == subset_words
  end

  def words_of(phrase)
    phrase.delete('&').split(/[, ():']+/).reject(&:empty?)
  end

  def stemmed_psql(synonyms)
    synonyms.map do |synonym|
      ActiveRecord::Base.connection.exec_query('select phraseto_tsquery($1) as query', 'SQL', [[nil, synonym]]).first['query']
    end.uniq
  end
end
