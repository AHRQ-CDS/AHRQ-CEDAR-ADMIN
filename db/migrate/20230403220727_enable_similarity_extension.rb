class EnableSimilarityExtension < ActiveRecord::Migration[6.1]
  def up
    enable_extension :pg_trgm
  end

  def down
    disable_extension :pg_trgm
  end
end
