class AddRepositoryDescription < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :description, :string

    Repository.find_by(fhir_id: 'uspstf')&.update(description:
      'The United States Preventive Services Task Force is an independent, ' \
      'volunteer panel of experts in prevention and evidence-based medicine.')

    Repository.find_by(fhir_id: 'cds-connect')&.update(description:
      'CDS Connect provides Clinical Decision Support artifacts that are based on clinical practice guidelines, ' \
      'peer-reviewed articles, best practices, and other content identified via PCOR.')

    Repository.find_by(fhir_id: 'ehc')&.update(description:
      'The AHRQ EHC Program\'s goal is to improve healthcare quality by enabling access to the best available evidence ' \
      'on outcomes and appropriateness of healthcare treatments, devices, and services.')

    Repository.find_by(fhir_id: 'epc')&.update(description:
      'Evidence-based Practice Centers are academic and other research institutions contracted by the EHC Program ' \
      'to evaluate and summarize healthcare evidence.')

    Repository.find_by(fhir_id: 'srdr')&.update(description:
      'The SRDR is a collaborative, web-based resource containing systematic review data that ' \
      'functions as both a data repository and a data extraction tool.')
  end
end
