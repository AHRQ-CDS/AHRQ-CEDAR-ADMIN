class AddAncestryToMeshTreeNodes < ActiveRecord::Migration[6.0]
  def change
    add_column :mesh_tree_nodes, :ancestry, :string
    add_index :mesh_tree_nodes, :ancestry
  end
end
