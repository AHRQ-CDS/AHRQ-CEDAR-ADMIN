class CreateMeshTreeNodes < ActiveRecord::Migration[6.0]
  def change
    create_table :mesh_tree_nodes do |t|
      t.string :code
      t.string :tree_number
      t.string :name
      t.text   :description

      t.timestamps
    end
  end
end
