class AddPublishedOnPrecisionToArtifacts < ActiveRecord::Migration[6.0]
  def change
    add_column :artifacts, :published_on_precision, :int
  end
end
