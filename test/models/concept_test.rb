# frozen_string_literal: true

require 'test_helper'

class ConceptTest < ActiveSupport::TestCase
  test 'synonyms are converted to PSQL tsqueries' do
    concept = Concept.new(name: 'Test', synonyms_text: ['foo', 'bar'])
    assert concept.synonyms_psql.include? 'foo'
    assert concept.synonyms_psql.include? 'bar'
  end

  test 'spaces in synonyms are handled' do
    concept = Concept.new(name: 'Test', synonyms_text: ['foo bar'])
    assert concept.synonyms_psql.include? 'foo<->bar'
  end

  test 'commas in synonyms are handled' do
    concept = Concept.new(name: 'Test', synonyms_text: ['foo,bar'])
    assert concept.synonyms_psql.include? 'foo<->bar'
  end

  test 'commas and spaces in synonyms are handled' do
    concept = Concept.new(name: 'Test', synonyms_text: ['foo, bar'])
    assert concept.synonyms_psql.include? 'foo<->bar'
  end

  test 'braces in synonyms are escaped' do
    concept = Concept.new(name: 'Test', synonyms_text: ['(foo),bar'])
    assert concept.synonyms_psql.include? '\(foo\)<->bar'
  end
end
