class AddToPublishedOnStartEndToArtifact < ActiveRecord::Migration[6.0]
  def change
    add_column :artifacts, :published_on_start, :datetime
    add_column :artifacts, :published_on_end, :datetime
  end
end
