# frozen_string_literal: true

require 'test_helper'

class ArtifactTest < ActiveSupport::TestCase
  test 'setting description text field with other fields blank' do
    artifact = Artifact.new(description: "Test\n\nTest")
    assert_equal "Test\n\nTest", artifact.description
    assert_equal '<p>Test</p> <p>Test</p>', artifact.description_html
    assert_equal "Test\n\n \n\nTest\n\n", artifact.description_markdown
  end

  test 'setting description text field with other fields set' do
    artifact = Artifact.new(description_html: 'HTML', description_markdown: 'MARKDOWN')
    artifact.description = 'TEXT'
    assert_equal 'HTML', artifact.description_html
    assert_equal "MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'TEXT', artifact.description
  end

  test 'setting description text field with only html field set' do
    artifact = Artifact.new(description_html: 'HTML')
    artifact[:description_markdown] = nil
    artifact.description = 'TEXT AND MARKDOWN'
    assert_equal 'HTML', artifact.description_html
    assert_equal "TEXT AND MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'TEXT AND MARKDOWN', artifact.description
  end

  test 'setting description text field with only markdown field set' do
    artifact = Artifact.new(description_markdown: 'MARKDOWN')
    artifact[:description_html] = nil
    artifact.description = 'TEXT AND HTML'
    assert_equal '<p>TEXT AND HTML</p>', artifact.description_html
    assert_equal "MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'TEXT AND HTML', artifact.description
  end

  test 'setting description html field with other fields blank' do
    artifact = Artifact.new(description_html: '<h2>Test</h2> <p>Test</p> <script>Test</script>')
    assert_equal 'Test Test Test', artifact.description
    assert_equal '<h2>Test</h2> <p>Test</p> Test', artifact.description_html
    assert_equal "## Test\n \n\nTest\n\n \n\nTest\n\n", artifact.description_markdown
  end

  test 'setting description html field with other fields set' do
    artifact = Artifact.new(description_markdown: 'MARKDOWN', description: 'TEXT')
    artifact.description_html = 'HTML'
    assert_equal "MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'TEXT', artifact.description
    assert_equal 'HTML', artifact.description_html
  end

  test 'setting description html field with only markdown field set' do
    artifact = Artifact.new(description_markdown: 'MARKDOWN')
    artifact[:description] = nil
    artifact.description_html = 'HTML AND TEXT'
    assert_equal "MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'HTML AND TEXT', artifact.description
    assert_equal 'HTML AND TEXT', artifact.description_html
  end

  test 'setting description html field with only text field set' do
    artifact = Artifact.new(description: 'TEXT')
    artifact[:description_markdown] = nil
    artifact.description_html = 'HTML AND MARKDOWN'
    assert_equal "HTML AND MARKDOWN\n\n", artifact.description_markdown
    assert_equal 'TEXT', artifact.description
    assert_equal 'HTML AND MARKDOWN', artifact.description_html
  end

  test 'setting description markdown field with other fields blank' do
    artifact = Artifact.new(description_markdown: "## Test\n\nTest")
    assert_equal 'Test Test', artifact.description
    assert_equal '<h2>Test</h2> <p>Test</p>', artifact.description_html
    assert_equal "## Test\n \n\nTest\n\n", artifact.description_markdown
  end

  test 'setting description markdown field with other fields set' do
    artifact = Artifact.new(description_html: 'HTML', description: 'TEXT')
    artifact.description_markdown = 'MARKDOWN'
    assert_equal 'HTML', artifact.description_html
    assert_equal 'TEXT', artifact.description
    assert_equal "MARKDOWN\n\n", artifact.description_markdown
  end

  test 'setting description markdown field with only html field set' do
    artifact = Artifact.new(description_html: 'HTML')
    artifact[:description] = nil
    artifact.description_markdown = 'MARKDOWN AND TEXT'
    assert_equal 'HTML', artifact.description_html
    assert_equal 'MARKDOWN AND TEXT', artifact.description
    assert_equal "MARKDOWN AND TEXT\n\n", artifact.description_markdown
  end

  test 'setting description markdown field with only text field set' do
    artifact = Artifact.new(description: 'TEXT')
    artifact[:description_html] = nil
    artifact.description_markdown = 'MARKDOWN AND HTML'
    assert_equal '<p>MARKDOWN AND HTML</p>', artifact.description_html
    assert_equal 'TEXT', artifact.description
    assert_equal "MARKDOWN AND HTML\n\n", artifact.description_markdown
  end

  test 'setting a valid URL' do
    repository = create(:repository)
    artifact = Artifact.new(url: 'http://example.com/', repository: repository)
    assert artifact.valid?, 'Valid URL should result in a valid artifact'
    artifact = Artifact.new(url: 'https://example.com/', repository: repository)
    assert artifact.valid?, 'Valid URL should result in a valid artifact'
  end

  test 'setting an invalid URL' do
    repository = create(:repository)
    artifact = Artifact.new(url: 'javascript:alert("XSS")', repository: repository)
    assert_not artifact.valid?, 'Invalid URL should result in an invalid artifact'
  end

  test 'normalizing keywords' do
    artifact = Artifact.new(keywords: ['Duplicate', 'duplicate'])
    assert_equal(1, artifact.keywords.size)
    assert_equal('duplicate', artifact.keywords.first)
    artifact = Artifact.new(keywords: ['cáncer', 'cancer'])
    assert_equal(1, artifact.keywords.size)
    assert_equal('cancer', artifact.keywords.first)
  end

  test 'associating concepts for keywords' do
    create_concepts(count: 2)
    artifact = Artifact.new(keywords: ['synonym 1a', 'synonym 2b', 'foo'])
    assert_equal(2, artifact.concepts.size)
    artifact.keywords = ['synonym 1a']
    assert_equal(1, artifact.concepts.size)
    assert_equal('CUI1', artifact.concepts.first.umls_cui)
    assert_equal('Description 1', artifact.concepts.first.umls_description)
    assert_equal('synonym 1a', artifact.concepts.first.codes[0]['description'])
    assert_equal('1a', artifact.concepts.first.codes[0]['code'])
    assert_equal('MSH', artifact.concepts.first.codes[0]['system'])
    artifact.keywords = ['synonym 3a']
    assert_equal(0, artifact.concepts.size)
    artifact.keywords = []
    assert_equal(0, artifact.concepts.size)
    artifact.keywords = nil
    assert_equal(0, artifact.concepts.size)
  end

  test 'setting published_on_start and published_on_end' do
    repository = create(:repository)

    # DAY PRECISION has a range with published_on_start and published_on_end across a 24-hour period
    artifact = Artifact.new(published_on: Date.new(2021, 2, 25), published_on_precision: 3, repository: repository)
    artifact.save!
    assert_equal(DateTime.parse('2021-02-25 00:00:00 UTC'), artifact.published_on_start.utc)
    assert_equal(DateTime.parse('2021-02-25 23:59:59 UTC'), artifact.published_on_end.utc)

    # MONTH PRECISION has a range with published_on_start and published_on_end across a month-long period
    artifact.update!(published_on_precision: 2, published_on: Date.new(2021, 2))
    assert_equal(DateTime.parse('2021-02-01 00:00:00 UTC'), artifact.published_on_start.utc)
    assert_equal(DateTime.parse('2021-02-28 23:59:59 UTC'), artifact.published_on_end.utc)

    # YEAR PRECISION has a range with published_on_start and published_on_end across a year-long period
    artifact.update!(published_on_precision: 1, published_on: Date.new(2021))
    assert_equal(DateTime.parse('2021-01-01 00:00:00 UTC'), artifact.published_on_start.utc)
    assert_equal(DateTime.parse('2021-12-31 23:59:59 UTC'), artifact.published_on_end.utc)

    # NIL PRECISION has a range with published_on_start and published_on_end both nil
    artifact.update!(published_on_precision: 0, published_on: nil)
    assert_nil(artifact.published_on_start)
    assert_nil(artifact.published_on_end)
  end
end
