# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Workaround for https://github.com/titusfortner/webdrivers/issues/247
# The eventual solution should be to update the version of selenium-webdriver
Webdrivers::Chromedriver.required_version = "114.0.5735.90"
