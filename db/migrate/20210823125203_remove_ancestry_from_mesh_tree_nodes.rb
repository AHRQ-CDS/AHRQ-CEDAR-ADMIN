class RemoveAncestryFromMeshTreeNodes < ActiveRecord::Migration[6.0]
  def change
    remove_column :mesh_tree_nodes, :ancestry
    add_column :mesh_tree_nodes, :parent_id, :bigint

    add_index :mesh_tree_nodes, :tree_number
    add_index :mesh_tree_nodes, :parent_id
  end
end
