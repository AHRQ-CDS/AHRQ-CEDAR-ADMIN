require_relative '../importers/uspstf'

namespace :import do
  desc "Download the USPSTF repository content and import it to the database"
  task uspstf: :environment do
    Importers::UspstfRepositoryImporter.download_and_update!
  end
end
