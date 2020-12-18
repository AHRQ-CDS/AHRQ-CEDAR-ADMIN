class AddRemoteIdentifierToArtifacts < ActiveRecord::Migration[6.0]
  def change
    add_column :artifacts, :remote_identifier, :string
  end
end
