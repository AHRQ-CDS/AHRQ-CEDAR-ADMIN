# Set up default connection parameters for Faraday
Faraday.default_connection_options.headers = {
  "User-Agent" => 'Mozilla/5.0 (compatible; Cedarbot/1.0; +https://cds.ahrq.gov/cedar)',
  "From" => ENV['CEDAR_TO_EMAIL'] || 'cedar@ahrq.hhs.gov'
}
