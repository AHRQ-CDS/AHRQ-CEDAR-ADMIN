# frozen_string_literal: true

require 'test_helper'

class ConceptImporterTest < ActiveSupport::TestCase
  test 'import concepts from UMLS MTH' do
    # Ensure that no concepts are loaded before the test runs
    assert_equal(0, Concept.all.count)

    ConceptImporter.import_umls_mrconso(file_fixture('umls_mth.rrf'))
    assert_equal(2, Concept.all.count)
    # import again and make sure the concepts weren't duplicated
    ConceptImporter.import_umls_mrconso(file_fixture('umls_mth.rrf'))
    assert_equal(2, Concept.all.count)

    concept = Concept.where(umls_cui: 'C0000001').first
    assert_equal('Foo desc', concept.umls_description)
    assert_equal(2, concept.synonyms_text.size)
    assert_equal(2, concept.codes.size)
    assert_equal('Foo', concept.codes[0]['description'])
    assert_equal('Baz', concept.codes[1]['description'])
    assert(concept.synonyms_text.include?('foo'))
    assert_not(concept.synonyms_text.include?('foo2'))
    assert_not(concept.synonyms_text.include?('bar'))
    assert(concept.synonyms_text.include?('baz'))

    concept = Concept.where(umls_cui: 'C0000002').first
    assert_equal('Abc desc', concept.umls_description)
    assert_equal(2, concept.synonyms_text.size)
    assert_equal(2, concept.codes.size)
    assert(concept.synonyms_text.include?('abc'))
    assert_not(concept.synonyms_text.include?('abc2'))
    assert_not(concept.synonyms_text.include?('def'))
    assert(concept.synonyms_text.include?('ghi'))
  end
end
