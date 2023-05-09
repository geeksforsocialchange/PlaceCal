# frozen_string_literal: true

ruby '2.7.6'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'minitest-rails'
gem 'pg'
gem 'puma'
gem 'rails'

# Frontend
gem 'coffee-rails'
gem 'importmap-rails'
gem 'jquery-rails'
gem 'jquery-turbolinks'
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
gem 'omniauth-facebook'
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
gem 'rails_autolink'

# Jobs
gem 'delayed_job_active_record'

# API
gem 'graphql'
gem 'rack-cors', require: 'rack/cors'

# Utilities
gem 'active_link_to'
gem 'bootsnap', require: false
gem 'enumerize'
gem 'friendly_id'
gem 'jbuilder'
gem 'listen'
gem 'oj'
gem 'paper_trail'
gem 'rollbar'
gem 'sendgrid-actionmailer'
gem 'uk_postcode'
gem 'virtus'
gem 'whenever', require: false

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'timecop'
end

group :development do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'graphiql-rails'
  gem 'letter_opener'
  gem 'rails-erd'
  gem 'rdoc'
  gem 'rubocop-graphql', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'
  gem 'yard'
end

group :test do
  gem 'capybara-select-2'
  gem 'graphql-client'
  gem 'json_matchers'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  # gem 'simplecov', require: false
  gem 'database_cleaner-active_record'
  gem 'vcr'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Use Redis for Action Cable
gem 'redis'
