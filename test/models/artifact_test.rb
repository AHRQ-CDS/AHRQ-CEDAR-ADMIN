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

  test 'getting all keywords from an artifact' do
    artifact = Artifact.new(keywords: ['one', 'two'], mesh_keywords: ['two', 'three'])
    assert_equal ['one', 'two', 'three'], artifact.all_keywords
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
    artifact = Artifact.new(keywords: ['Duplicate', 'duplicate'], mesh_keywords: ['MeSH_Duplicate', 'mesh_duplicate'])
    assert_equal(1, artifact.keywords.size)
    assert_equal('duplicate', artifact.keywords.first)
    assert_equal(1, artifact.mesh_keywords.size)
    assert_equal('mesh_duplicate', artifact.mesh_keywords.first)
    artifact = Artifact.new(keywords: ['cáncer', 'cancer'], mesh_keywords: ['cáncer', 'cancer'])
    assert_equal(1, artifact.keywords.size)
    assert_equal('cancer', artifact.keywords.first)
    assert_equal(1, artifact.mesh_keywords.size)
    assert_equal('cancer', artifact.mesh_keywords.first)
  end
end
