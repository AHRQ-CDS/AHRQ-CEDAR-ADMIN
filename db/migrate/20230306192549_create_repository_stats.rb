class CreateRepositoryStats < ActiveRecord::Migration[6.1]
  def change
    create_view :repository_stats
  end
end
