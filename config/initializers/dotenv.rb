# Ensure that required environment variables are set

Dotenv.require_keys("CEDAR_USPSTF_API_KEY")

Dotenv.require_keys("CEDAR_CDS_CONNECT_BASIC_AUTH_USERNAME")
Dotenv.require_keys("CEDAR_CDS_CONNECT_BASIC_AUTH_PASSWORD")
Dotenv.require_keys("CEDAR_CDS_CONNECT_USERNAME")
Dotenv.require_keys("CEDAR_CDS_CONNECT_PASSWORD")
Dotenv.require_keys("CEDAR_CDS_CONNECT_BASE_URL")

Dotenv.require_keys("CEDAR_SRDR_BASE_URL")
Dotenv.require_keys("CEDAR_SRDR_API_KEY")

Dotenv.require_keys("CEDAR_EHC_FEED_URL")

Dotenv.require_keys("CEDAR_NGC_BASE_URL")
