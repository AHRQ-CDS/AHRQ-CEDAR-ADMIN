# frozen_string_literal: true

namespace :import do
  desc 'Download the USPSTF repository content and import it to the database'
  task uspstf: :environment do
    puts 'Importing data from USPSTF'
    if UspstfImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts'] || !ran
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Download the CDS Connect repository content and import it to the database'
  task cds_connect: :environment do
    puts 'Importing data from CDS Connect'
    if CdsConnectImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Download the EHC repository content and import it to the database'
  task ehc: :environment do
    puts 'Importing data from EHC'
    if EhcImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Download the EPC repository content and import it to the database'
  task epc: :environment do
    puts 'Importing data from EPC'
    if EpcImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Download the SRDR repository content and import it to the database'
  task srdr: :environment do
    puts 'Importing data from SRDR'
    if SrdrImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Download the NGC repository content locally'
  task ngc: :environment do
    puts 'Importing data from NGC'
    if NgcImporter.run
      Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
    else
      puts 'Skipped, importer disabled'
    end
  end

  desc 'Import concepts from UMLS MRCONSO file'
  task umls_concepts: :environment do
    puts 'Importing concepts'
    ConceptImporter.import_umls_mrconso('datafiles/MRCONSO.RRF')
    Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
  end

  desc 'Import MESH Concepts'
  task mesh_concepts: :environment do
    puts 'Importing MESH'
    MeshImporter.import_mesh('datafiles/desc2021.xml')
    Rake::Task["import:update_counts"].invoke() unless ENV['dont_update_artifact_counts']
  end

  desc 'Update artifact count for MeSH concepts'
  task update_counts: :environment do
    puts 'Updating artifact counts for MeSH concepts'
    MeshImporter.update_artifact_counts
  end

  desc 'Download all repository content and import it to the database'
  task all: :environment do
    ENV['dont_update_artifact_counts'] = 'true'
    %w(uspstf cds_connect ehc epc srdr).each do |task|
      Rake::Task["import:#{task}"].invoke()
    end
    Rake::Task["import:update_counts"].invoke()
  end
end
