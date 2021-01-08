require_relative '../../app/importers/uspstf_importer'

namespace :import do
  desc "Download the USPSTF repository content and import it to the database"
  task uspstf: :environment do
    UspstfImporter.download_and_update!
  end

  desc "Load test fixure USPSTF repository content into the database"
  task uspstf_test_data: :environment do
    json = IO.read('test/fixtures/files/uspstf_sample.json')
    importer = UspstfImporter.new(json)
    importer.update_db!
  end

end
