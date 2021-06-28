# frozen_string_literal: true

namespace :import do
  desc 'Download the USPSTF repository content and import it to the database'
  task uspstf: :environment do
    puts 'Importing data from USPSTF'
    UspstfImporter.run
  end

  desc 'Load test fixure USPSTF repository content into the database'
  task uspstf_test_data: :environment do
    json = IO.read('test/fixtures/files/uspstf_sample.json')
    importer = UspstfImporter.new(json)
    importer.update_db!
  end

  desc 'Download the CDS Connect repository content and import it to the database'
  task cds_connect: :environment do
    puts 'Importing data from CDS Connect'
    CdsConnectImporter.run
  end

  desc 'Download the EHC repository content and import it to the database'
  task ehc: :environment do
    puts 'Importing data from EHC'
    EhcImporter.run
  end

  desc 'Download the EPC repository content and import it to the database'
  task epc: :environment do
    puts 'Importing data from EPC'
    EpcImporter.run
  end

  desc 'Download the SRDR repository content and import it to the database'
  task srdr: :environment do
    puts 'Importing data from SRDR'
    SrdrImporter.run
  end

  desc 'Download the NGC repository content locally'
  task ngc: :environment do
    puts 'Importing data from NGC'
    NgcImporter.run
  end

  desc 'Import concepts from UMLS MRCONSO file'
  task umls_concepts: :environment do
    puts 'Importing concepts'
    ConceptImporter.import_umls_mrconso('MRCONSO.RRF')
  end

  desc 'Download all repository content and import it to the database'
  task all: %i(uspstf cds_connect ehc epc srdr)
end
