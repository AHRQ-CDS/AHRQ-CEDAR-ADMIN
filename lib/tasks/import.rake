require_relative '../../app/importers/uspstf_importer'

namespace :import do
  desc "Download the USPSTF repository content and import it to the database"
  task uspstf: :environment do
    UspstfImporter.download_and_update!
  end
end
