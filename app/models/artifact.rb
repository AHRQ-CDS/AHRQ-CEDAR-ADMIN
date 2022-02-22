# frozen_string_literal: true

# Represents a clinical evidence artifact stored in one of the repositories
# indexed by CEDAR.
class Artifact < ApplicationRecord
  belongs_to :repository
  has_and_belongs_to_many :concepts
  after_save :update_index

  # Track all revisions to artifacts
  has_paper_trail ignore: [:updated_at]

  enum artifact_status: {
    draft: 'draft',
    active: 'active',
    archived: 'archived',
    unknown: 'unknown'
    retracted: 'retracted'
  }

  # Validate URLs to ensure that they begin with "http"; this allows "http://" and "https://" but prevents
  # "javascript:" and "data:", which are both security issues
  validates :url, format: { with: /\Ahttp(s)?:.*\z/i, message: 'only valid URLs' }, allow_nil: true

  # Handle setting of description fields; there are 3 different fields:
  #
  #   description - plain text description
  #   desctription_html - sanitized HTML description
  #   description_markdown - sanitized markdown description
  #
  # Each of these fields can be set independently, with the following behavior: if any of the other fields are
  # not yet set, they're automatically set as best possible based on the data supplied to the field being set,
  # sanitizing where appropriate. This approach 1) simplifies setting in the importers (e.g. just the HTML
  # version can be set in the importer and everything else will be set automatically), and 2) allows each field
  # to be set indivually if desired without overwriting the others (since the others are only set if nil)
  def description=(text)
    # Set all three fields based on the text version, adding paragraphs for
    # linefeeds by interpreting as Markdown
    super(text)
    return unless text

    html = CommonMarker.render_html(text, :DEFAULT)
    self.description_html ||= html
    self.description_markdown ||= text
  end

  def description_html=(html)
    # Set all three fields based on a white list filtered version of the HTML
    # TODO: This sanitizer changes <p>test</p><p>test</p> to "testtest" instead of "test test"
    if html
      html = ActionView::Base.safe_list_sanitizer.sanitize(html)&.squish
      super(html)
      self.description_markdown ||= ReverseMarkdown.convert(html)
      self.description ||= ActionView::Base.full_sanitizer.sanitize(html)
    else
      super(html)
    end
  end

  def description_markdown=(markdown)
    # Set all three fields based on a white list filtered version of the Markdown
    # (since Markdown can technically embed HTML)
    if markdown
      html = CommonMarker.render_html(markdown, :DEFAULT)
      html = ActionView::Base.safe_list_sanitizer.sanitize(html)&.squish
      markdown = ReverseMarkdown.convert(html)
      super(markdown)
      self.description_html ||= html
      self.description ||= ActionView::Base.full_sanitizer.sanitize(html)
    else
      super(markdown)
    end
  end

  def update_concepts
    mapped_concepts = []
    keywords&.each do |keyword|
      matching_concepts = Concept.where('synonyms_text @> ?', "[\"#{keyword}\"]")
      mapped_concepts.concat(matching_concepts)
    end
    self.concepts = mapped_concepts.uniq
  end

  # Preprocess keywords (both regular and MeSH) to normalize, remove duplicates, and store for searching

  def keywords=(keywords)
    keywords = keywords&.map { |k| I18n.transliterate(k).downcase }&.uniq
    super(keywords)
    self.keyword_text = keywords&.join(', ')
    update_concepts
  end

  # When being displayed to a user, show the title
  def to_s
    title
  end

  def update_index
    query = <<-SQL.squish
      UPDATE artifacts SET content_search = (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(keyword_text, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'C'))
      WHERE id=#{ActiveRecord::Base.connection.quote(id)}
    SQL
    ActiveRecord::Base.connection.execute(query)
  end
end
