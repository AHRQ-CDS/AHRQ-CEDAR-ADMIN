class AddRepositoryEnabledFlag < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :enabled, :boolean, :default => true
  end
end
