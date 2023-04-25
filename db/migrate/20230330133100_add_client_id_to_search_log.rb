class AddClientIdToSearchLog < ActiveRecord::Migration[6.0]
  def change
    add_column :search_logs, :client_id, :string
  end
end
