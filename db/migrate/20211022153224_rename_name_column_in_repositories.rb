class RenameNameColumnInRepositories < ActiveRecord::Migration[6.0]
  def change
    rename_column :repositories, :name, :alias
    add_column :repositories, :name, :string
  end
end
