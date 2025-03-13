# frozen_string_literal: true

ruby '3.3.6'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'minitest-rails'
gem 'pg'
gem 'puma'
gem 'rails', '7.2.2.1'

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
gem 'appsignal'
gem 'auto_strip_attributes'
gem 'bootsnap', require: false
gem 'csv'
gem 'enumerize'
gem 'friendly_id'
# gem 'listen' # needed?
gem 'invisible_captcha'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'observer'
gem 'paper_trail'
gem 'uk_postcode'

group :development, :test do
  gem 'byebug'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'timecop'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'foreman'
  gem 'graphiql-rails'
  gem 'letter_opener'
  gem 'rails-erd'
  gem 'rdoc'
  gem 'rubocop', '1.74.0', require: false
  gem 'rubocop-graphql', '1.5.4', require: false
  gem 'rubocop-minitest', '0.37.1', require: false
  gem 'rubocop-performance', '1.24.0', require: false
  gem 'rubocop-rails', '2.30.3', require: false
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
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'vcr'
  gem 'webmock' # used by VCR
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
