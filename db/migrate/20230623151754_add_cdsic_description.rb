class AddCdsicDescription < ActiveRecord::Migration[6.0]
  def change
    Repository.find_by(fhir_id: 'cdsic')&.update(description:
      'The Clinical Decision Support Innovation Collaborative (CDSiC) is a diverse community of ' \
      'experts at the forefront of using technology to better engage patients in their own care.')
  end
end
