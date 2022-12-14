class CreateArtifacts < ActiveRecord::Migration[6.0]
  def change
    create_table :artifacts do |t|
      t.string :title
      t.text :description
      t.text :description_html
      t.text :description_markdown
      t.references :repository, null: false, foreign_key: true
      t.string :url
      t.string :doi
      t.string :remote_identifier
      t.string :cedar_identifier
      t.string :artifact_type
      t.string :artifact_status
      t.date :published_on
      t.jsonb :keywords, default: []
      t.text :keyword_text
      t.tsvector :content_search

      t.timestamps
    end
    # TODO: Confirm that these are reasonable indexes for how we wind up using keywords
    add_index :artifacts, :keywords, :using => :gin, :name => 'index_artifacts_on_keywords'
    add_index :artifacts, :content_search, :using => :gin, :name => 'index_artifacts_on_content_search'
    add_index :artifacts, "to_tsvector('english', coalesce(keyword_text, ''))", :using => :gin, :name => 'index_artifacts_on_keyword_text'
  end
end
