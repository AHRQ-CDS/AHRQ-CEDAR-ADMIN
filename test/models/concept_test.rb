# frozen_string_literal: true

require 'test_helper'

class ConceptTest < ActiveSupport::TestCase
  test 'synonyms are converted to PSQL tsqueries' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo', 'bar'])
    assert concept.synonyms_psql.include? "'foo'"
    assert concept.synonyms_psql.include? "'bar'"
  end

  test 'spaces in synonyms are handled' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo bar'])
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test 'commas in synonyms are handled' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo,bar'])
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test 'commas and spaces in synonyms are handled' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo, bar'])
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test 'braces in synonyms are ignored' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['(foo),bar'])
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test 'colons in synonyms are ignored' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo::bar'])
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test 'duplicate synonyms are ignored' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo bar', 'foo, bar'])
    assert_equal 1, concept.synonyms_psql.size
  end

  test 'subset synonyms are ignored' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['foo bar', 'foo, bar', 'foo bar, baz'])
    assert_equal 3, concept.synonyms_text.size
    assert_equal 1, concept.synonyms_psql.size
    assert concept.synonyms_psql.include? "'foo' <-> 'bar'"
  end

  test '& is removed' do
    concept = Concept.new(umls_cui: 'Test', synonyms_text: ['prevention & control', 'sk&f 105494', 'sk&f-105494', 'sk&f 105,494'])
    assert_equal 4, concept.synonyms_text.size
    assert_equal 4, concept.synonyms_psql.size
    assert concept.synonyms_psql.include? "'prevent' <-> 'control'"
    assert concept.synonyms_psql.include? "'sk' <-> 'f' <-> '105494'"
    assert concept.synonyms_psql.include? "'sk' <-> 'f' <-> '-105494'"
    assert concept.synonyms_psql.include? "'sk' <-> 'f' <-> '105' <-> '494'"
  end
end
