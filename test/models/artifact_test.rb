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
end
