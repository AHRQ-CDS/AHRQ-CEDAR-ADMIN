class AddArtifactCountsToMeshTreeNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :mesh_tree_nodes, :direct_artifact_count, :integer
    add_column :mesh_tree_nodes, :indirect_artifact_count, :integer
    add_index :mesh_tree_nodes, :code
  end
end
