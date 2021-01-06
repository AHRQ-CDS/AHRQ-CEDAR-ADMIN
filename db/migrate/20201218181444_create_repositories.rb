class CreateRepositories < ActiveRecord::Migration[6.0]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
