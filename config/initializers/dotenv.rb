# Ensure that required environment variables are set; we only need to check for these if we're running one of
# the import rake tasks

if ($0.match(/(rails|rake)/) && ARGV.any? { |arg| arg.match(/^import/) })

  Dotenv.require_keys("CEDAR_USPSTF_API_KEY")

  Dotenv.require_keys("CEDAR_CDS_CONNECT_USERNAME")
  Dotenv.require_keys("CEDAR_CDS_CONNECT_PASSWORD")
  Dotenv.require_keys("CEDAR_CDS_CONNECT_BASE_URL")

  Dotenv.require_keys("CEDAR_SRDR_BASE_URL")
  Dotenv.require_keys("CEDAR_SRDR_API_KEY")

  Dotenv.require_keys("CEDAR_EHC_FEED_URL")

  # NGC is not imported in production
  # Dotenv.require_keys("CEDAR_NGC_BASE_URL")

end
