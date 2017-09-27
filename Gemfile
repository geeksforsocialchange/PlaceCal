ruby '2.4.1'
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
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# Calendar
gem 'icalendar'
gem 'icalendar-recurrence'

# Misc
gem 'carrierwave'
gem 'devise'
gem 'enumerize'
gem 'geocoder'
gem 'jbuilder', '~> 2.5'
gem 'koala'
gem 'listen', '~> 3.0.5'
gem 'mailgun_rails'
gem 'paranoia', '~> 2.2'
gem 'virtus'

gem 'whenever', require: false

# Styleguide
gem 'mountain_view'

# Helpers to group by time period
gem 'groupdate'

# Administration
gem 'administrate'
gem 'administrate-field-password'

# Markdown
gem 'kramdown'

gem 'delayed_job_active_record'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
end

group :development do
  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'awesome_print'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails-erd', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an IRB console on exception pages or by using <%= console %>
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
