# frozen_string_literal: true

ruby '3.1.2'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'minitest-rails'
gem 'pg'
gem 'puma'
gem 'rails', '7.1.3.2'

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
gem 'bootstrap'
gem 'cocoon'
gem 'font-awesome-rails'
gem 'select2-rails'
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
gem 'bootsnap', require: false
gem 'enumerize'
gem 'friendly_id'
# gem 'listen' # needed?
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

gem 'invisible_captcha'
gem 'paper_trail'
gem 'rollbar'
gem 'uk_postcode'

group :development, :test do
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'timecop'
end

group :development do
  gem 'better_errors'
  gem 'foreman'
  gem 'graphiql-rails'
  gem 'letter_opener'
  gem 'rails-erd'
  gem 'rdoc'
  gem 'rubocop', '1.62.0', require: false
  gem 'rubocop-graphql', '1.5.0', require: false
  gem 'rubocop-minitest', '0.35.0', require: false
  gem 'rubocop-performance', '1.20.2', require: false
  gem 'rubocop-rails', '2.24.0', require: false
  gem 'rubocop-rake', require: false
  gem 'spring'
  # gem 'spring-watcher-listen'
  gem 'web-console'
  gem 'yard'
end

group :test do
  # gem 'simplecov', require: false
  gem 'capybara-select-2'
  gem 'database_cleaner-active_record'
  gem 'graphql-client'
  gem 'json_matchers'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'minitest-retry'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'vcr'
  gem 'webmock' # used by VCR
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
