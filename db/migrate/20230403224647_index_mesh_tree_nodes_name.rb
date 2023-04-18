class IndexMeshTreeNodesName < ActiveRecord::Migration[6.1]
  # Assumes :pg_trgm extension enabled
  def up
    add_index :mesh_tree_nodes, :name, :using => :gin, :opclass => :gin_trgm_ops, :name => 'index_mesh_tree_nodes_on_name_trigrams'
  end

  def down
    remove_index :mesh_tree_nodes, :name, name: 'index_mesh_tree_nodes_on_name_trigrams'
  end
end
