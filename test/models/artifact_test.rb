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
end
