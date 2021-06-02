# frozen_string_literal: true

require 'test_helper'

class SynonymImportTest < ActiveSupport::TestCase
  test 'import synonyms from UMLS MTH' do
    # Ensure that no concepts are loaded before the test runs
    assert_equal(0, Concept.all.count)

    SynonymImporter.import_umls_mrconso(file_fixture('umls_mth.rrf'))
    assert_equal(2, Concept.all.count)

    concept = Concept.where(name: 'C0000001').first
    assert_equal(3, concept.synonyms_text.size)
    assert(concept.synonyms_text.include?('foo'))
    assert_not(concept.synonyms_text.include?('foo2'))
    assert(concept.synonyms_text.include?('bar'))
    assert(concept.synonyms_text.include?('baz'))

    concept = Concept.where(name: 'C0000002').first
    assert_equal(3, concept.synonyms_text.size)
    assert(concept.synonyms_text.include?('abc'))
    assert_not(concept.synonyms_text.include?('abc2'))
    assert(concept.synonyms_text.include?('def'))
    assert(concept.synonyms_text.include?('ghi'))
  end
end
