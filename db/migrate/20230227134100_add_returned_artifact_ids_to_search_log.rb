class AddReturnedArtifactIdsToSearchLog < ActiveRecord::Migration[6.0]
  def change
    add_column :search_logs, :returned_artifact_ids, :jsonb, default: []
  end
end
