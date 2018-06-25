# frozen_string_literal: true

ruby '2.4.3'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core
gem 'pg'
gem 'puma', '~> 3.0'
gem 'rails', '~> 5.1.0'

# Frontend
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# Calendar
gem 'httparty'
gem 'icalendar'
gem 'icalendar-recurrence'

# Uploads
gem 'carrierwave'
gem 'mini_magick'

# UI
gem 'bootstrap-sass', '~> 3.3.7'

# Misc
gem 'active_link_to'
gem 'devise'
gem 'enumerize'
gem 'friendly_id', '~> 5.1.0'
gem 'geocoder'
gem 'jbuilder', '~> 2.5'
gem 'koala'
gem 'leaflet-rails'
gem 'listen', '~> 3.0.5'
gem 'mailgun_rails'
gem 'nested_form'
gem 'oj'
gem 'paper_trail'
gem 'pundit'
gem 'rollbar'
gem 'select2-rails'
gem 'simple_form'
gem 'virtus'
gem 'whenever', require: false

# Styleguide
gem 'mountain_view'

# Helpers to group by time period
# TODO: check if this is still actually used
gem 'groupdate'

# Administration
gem 'administrate'
gem 'administrate-field-carrierwave', '~> 0.2.0'
gem 'administrate-field-password'

# Markdown
gem 'kramdown'
gem 'rails_autolink'

# Jobs
gem 'delayed_job_active_record'

# CORS to allow iFrames
gem 'rack-cors', require: 'rack/cors'

# Seeds and data stuff
gem 'seed_migration'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  # Generates factories for us
  gem 'timecop'
  gem 'to_factory', '~> 0.2.1'
end

group :development do
  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-minitest'
  gem 'pry-rails'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'rails-erd', require: false
  gem 'rubocop'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an IRB console on exception pages or by using <%= console %>
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'faker'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
