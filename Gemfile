# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.7', '< 7.0'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.4'
# We've replaced Turbolinks with the newer Turbo package
gem 'turbo-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Schedule tasks using whenever
gem 'whenever'

# Read environment variables from the .env file
gem 'dotenv-rails'

# Use faraday for HTTP request sessions where cookies need to be managed
gem 'faraday', '~> 2.7'
gem 'faraday-cookie_jar'
gem 'faraday-follow_redirects'

# Use PDF Reader gem for processing PDF artifacts during indexing
gem 'pdf-reader'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Convert Markdown to HTML
gem 'commonmarker'

# Convert HTML to Markdown
gem 'reverse_markdown'

# Display charts
gem 'chartkick'

# Track changes to artifacts over time
gem 'paper_trail'
gem 'diffy'

# Sequel: Group by date
gem 'groupdate'

# Table-based pagination
gem 'kaminari'

# LDAP authentication support
gem 'devise'
gem 'devise_ldap_authenticatable'

# Get the precision of a date
# gem 'date_time_precision'
gem 'date_time_precision', require: false

# Support for database views
gem 'scenic'

# Lookup IP addresses
gem 'rdap'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  # Use factory bot instead of fixtures
  gem 'factory_bot_rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'brakeman', '>= 5.3', require: false
  # Support Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webmock'
  # Allow testing of controller assignments
  gem 'rails-controller-testing'
  # Support some level of automated testing for accessibility compliance
  gem 'axe-core-api'
end

# Windows does not include zoneinfo files; this will bundle the tzinfo-data gem if running on Windows is required
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
