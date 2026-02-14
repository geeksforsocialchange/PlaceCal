# frozen_string_literal: true

ruby '4.0.1'
source 'https://gem.coop'

# Core
gem 'pg'                          # PostgreSQL database adapter
gem 'puma'                        # Web server
gem 'rails', '~> 8.0'             # Web framework

# Frontend
gem 'importmap-rails'             # ES module imports without bundling
gem 'sass-rails', '6.0.0'         # SCSS stylesheets (public site)
gem 'stimulus-rails'              # Stimulus JS controllers
gem 'turbo-rails'                 # Turbo Drive/Frames/Streams

# Calendar importers
gem 'eventbrite_sdk'              # Eventbrite API client
gem 'httparty'                    # HTTP requests for feed fetching
gem 'icalendar'                   # ICS feed parsing
gem 'icalendar-recurrence'        # Recurring event expansion
gem 'json-ld'                     # Schema.org structured data parsing

# Data and UI
gem 'ajax-datatables-rails'       # Server-side datatable rendering
gem 'ancestry'                    # Neighbourhood tree hierarchy
gem 'carrierwave'                 # File uploads (logos, hero images)
gem 'friendly_id'                 # Human-readable URL slugs
gem 'groupdate'                   # Group events by day/week/month
gem 'image_processing'            # Image resizing for uploads
gem 'kramdown'                    # Markdown to HTML rendering
gem 'simple_form'                 # Form builder
gem 'view_component'              # Encapsulated view components

# Auth and permissions
gem 'devise'                      # User authentication
gem 'devise_invitable'            # User invitation emails
gem 'pundit'                      # Authorization policies

# Geolocation
gem 'geocoder'                    # Postcode to lat/lon via postcodes.io
gem 'uk_postcode'                 # UK postcode validation and parsing

# API
gem 'graphql'                     # GraphQL API
gem 'rack-cors', require: 'rack/cors' # Cross-origin request support

# Background jobs
gem 'delayed_job_active_record'   # Async job queue (calendar imports)

# Utilities
gem 'appsignal'                   # Error tracking and performance monitoring
gem 'auto_strip_attributes'       # Strip whitespace from model attributes
gem 'bootsnap', require: false    # Boot time optimisation
gem 'csv'                         # CSV parsing (neighbourhood data imports)
gem 'enumerize'                   # Enumerated attributes (site theme, badge zoom)
gem 'invisible_captcha'           # Spam protection on contact form
gem 'paper_trail'                 # Event version tracking and audit log

group :development, :test do
  gem 'byebug'                    # Debugger
  gem 'dotenv-rails'              # Load .env files
end

group :development do
  gem 'better_errors'             # Better error pages
  gem 'binding_of_caller'         # REPL in error pages
  gem 'database_consistency', require: false # Schema validation
  gem 'foreman'                   # Process manager (Procfile.dev)
  gem 'graphiql-rails'            # GraphQL IDE at /graphiql
  gem 'letter_opener'             # Preview emails in browser
  gem 'rails-erd'                 # Entity-relationship diagrams
  gem 'rdoc'                      # Documentation generator
  gem 'rubocop', '1.84.1', require: false
  gem 'rubocop-graphql', '1.6.0', require: false
  gem 'rubocop-performance', '1.26.1', require: false
  gem 'rubocop-rails', '2.34.3', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'spring'                    # Application preloader
  gem 'web-console'               # In-browser Rails console
  gem 'yard'                      # API documentation
end

group :test do
  gem 'axe-core-rspec', '~> 4.8'  # Accessibility testing
  gem 'capybara'                  # Browser simulation
  gem 'cucumber-rails', require: false # BDD acceptance tests
  gem 'database_cleaner-active_record' # Clean DB between tests
  gem 'factory_bot_rails'         # Test data factories
  gem 'faker'                     # Fake data generation
  gem 'graphql-client'            # GraphQL API test client
  gem 'pundit-matchers', '~> 4.0' # Policy spec matchers
  gem 'rspec-rails', '~> 8.0'     # Test framework
  gem 'selenium-webdriver'        # Browser driver for system tests
  gem 'shoulda-matchers', '~> 7.0' # Model/controller matchers
  gem 'simplecov', require: false # Code coverage
  gem 'timecop'                   # Time travel in tests
  gem 'vcr'                       # Record/replay HTTP interactions
  gem 'webmock'                   # Stub HTTP requests (used by VCR)
end

# Run `bin/setup-ai` to enable, or manually: bundle config set --local with ai && bundle install
group :ai, optional: true do
  gem 'claude-on-rails'
end
