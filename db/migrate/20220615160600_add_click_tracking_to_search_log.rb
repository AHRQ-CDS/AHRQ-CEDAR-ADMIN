class AddClickTrackingToSearchLog < ActiveRecord::Migration[6.0]
  def change
    add_column :search_logs, :link_clicks, :jsonb, default: []
  end
end
