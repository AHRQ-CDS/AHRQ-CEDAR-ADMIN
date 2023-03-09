class CreateArtifactSearchStats < ActiveRecord::Migration[6.1]
  def change
    create_view :artifact_search_stats
  end
end
