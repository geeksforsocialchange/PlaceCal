# frozen_string_literal: true

ruby '3.3.6'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'pg'
gem 'puma'
gem 'rails', '7.2.3'

# Frontend
gem 'coffee-rails'
gem 'jquery-rails'
gem 'jsbundling-rails'
gem 'sass-rails', '6.0.0'
gem 'stimulus-rails'
gem 'turbo-rails'

# Backend
gem 'ancestry'

# Datatables
gem 'ajax-datatables-rails'

# Calendar
gem 'eventbrite_sdk'
gem 'httparty'
gem 'icalendar'
gem 'icalendar-recurrence'
gem 'json-ld'

# Uploads
gem 'carrierwave'
gem 'image_processing'

# Admin
gem 'font-awesome-rails'
gem 'simple_form'

# Users, login, permissions
gem 'devise'
gem 'devise_invitable'
gem 'pundit'

# Maps and geolocation
gem 'geocoder'
gem 'leaflet-rails'

# Styleguide
gem 'mountain_view'
gem 'view_component'

# Helpers to group by time period
gem 'groupdate'

# Markdown
gem 'kramdown'

# Jobs
gem 'delayed_job_active_record'

# API
gem 'graphql'
gem 'rack-cors', require: 'rack/cors'

# Utilities
gem 'appsignal'
gem 'auto_strip_attributes'
gem 'bootsnap', require: false
gem 'csv'
gem 'enumerize'
gem 'friendly_id'
# gem 'listen' # needed?
gem 'invisible_captcha'
gem 'mutex_m' # Fixes an warning with the spring gemspec - can remove later
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'observer'
gem 'paper_trail'
gem 'uk_postcode'

group :development, :test do
  gem 'byebug'
  gem 'dotenv-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'database_consistency', require: false
  gem 'foreman'
  gem 'graphiql-rails'
  gem 'letter_opener'
  gem 'rails-erd'
  gem 'rdoc'
  gem 'rubocop', '1.82.1', require: false
  gem 'rubocop-graphql', '1.5.6', require: false
  gem 'rubocop-performance', '1.26.1', require: false
  gem 'rubocop-rails', '2.34.3', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'spring'
  # gem 'spring-watcher-listen'
  gem 'web-console'
  gem 'yard'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', require: false
  gem 'cuprite', '0.15'  # Used by Cucumber tests
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'graphql-client'
  gem 'json_matchers'
  gem 'parallel_tests'
  gem 'pundit-matchers', '~> 3.0'
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 7.0'
  gem 'selenium-webdriver'  # Used by RSpec system tests (more stable in CI than Cuprite)
  gem 'shoulda-matchers', '~> 6.0'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock' # used by VCR
end

# Run `bin/setup-ai` to enable, or manually: bundle config set --local with ai && bundle install
group :ai, optional: true do
  gem 'claude-on-rails'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
