# frozen_string_literal: true

ruby '2.7.4'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'pg'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.2.3'
gem 'sprockets-rails'

# Frontend
gem 'coffee-rails', '~> 5.0'
gem 'importmap-rails'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'sass-rails', '~> 6.0'
gem 'stimulus-rails'
gem 'turbolinks', '~> 5' # TODO: This needs swapping out for 'turbo-rails'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 5.4.3'

# Backend
gem 'ancestry'

# Datatables
gem 'ajax-datatables-rails'

# Calendar
gem 'httparty'
gem 'icalendar'
gem 'icalendar-recurrence'
gem 'eventbrite_sdk'

# Uploads
gem 'carrierwave'
gem 'image_processing'

# Admin
gem 'bootstrap', '~> 4.4.1'
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
gem 'geocoder', '~> 1.6.0'
gem 'leaflet-rails'

# Styleguide
gem 'mountain_view'

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

# Seeds and data
gem 'seed_migration'

# Utilities
gem 'active_link_to'
gem 'bootsnap', require: false
gem 'crypt_keeper'
gem 'enumerize'
gem 'friendly_id', '~> 5.3.0'
gem 'jbuilder', '~> 2.5'
gem 'koala'
gem 'listen', '~> 3.2.0'
# gem 'net-http' # Prevents test deprecation warning
gem 'oj'
gem 'paper_trail'
gem 'rollbar'
gem 'virtus'
gem 'whenever', require: false

group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'timecop'
end

group :development do
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-minitest'
  gem 'letter_opener'
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'rubocop-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console'
  gem 'yard'
  gem 'graphiql-rails'
end

group :test do
  gem 'capybara'
  gem 'json_matchers'
  gem 'minitest-reporters'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  # gem 'simplecov', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
