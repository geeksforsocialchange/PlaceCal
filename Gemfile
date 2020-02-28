# frozen_string_literal: true

ruby '2.6.5'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'pg'
gem 'puma', '~> 4.3'
gem 'rails', '~> 6.0'
gem 'minitest-rails'

# Frontend
gem 'coffee-rails', '~> 5.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'sass-rails', '~> 6.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker'

# Calendar
gem 'httparty'
gem 'icalendar'
gem 'icalendar-recurrence'

# Uploads
gem 'carrierwave'
gem 'mini_magick'

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

# API / iFrames
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-rails'
gem 'grape_on_rails_routes'
gem 'rack-cors', require: 'rack/cors'

# Seeds and data
gem 'seed_migration'

# Utilities
gem 'active_link_to'
gem 'bootsnap', require: false
# Temp fix until https://github.com/jmazzi/crypt_keeper works with Rails 6
gem 'crypt_keeper', github: 'taylorwilliams/crypt_keeper'
gem 'enumerize'
gem 'friendly_id', '~> 5.3.0'
gem 'jbuilder', '~> 2.5'
gem 'koala'
gem 'listen', '~> 3.2.0'
gem 'oj'
gem 'paper_trail'
gem 'rollbar'
gem 'sendgrid-actionmailer'
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
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-minitest'
  gem 'rails-erd'
  gem 'rubocop-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  gem 'yard'
end

group :test do
  gem 'json_matchers'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
