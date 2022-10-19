class AddRepositoryDescription < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :description, :string
    Repository.find_each do |repository|
      case repository.fhir_id
      when 'uspstf'
        repository.description = 'Volunteer panel of experts developing evidence-based recommendations about clinical recommendations'
      # other repositories here #
      end
      repository.save!
    end
  end
end
