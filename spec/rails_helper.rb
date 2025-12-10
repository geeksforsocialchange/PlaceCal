# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'pundit/rspec'

# Load all support files
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # Use transactional fixtures for non-system specs
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot syntax methods
  config.include FactoryBot::Syntax::Methods

  # Include Devise test helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # Freeze time in tests (matching legacy behavior)
  config.before do
    Timecop.freeze(Time.zone.local(2022, 11, 8))
  end

  config.after do
    Timecop.return
  end

  # Database cleaner for system/feature specs
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do |example|
    DatabaseCleaner.start if example.metadata[:type].in?(%i[system feature])
  end

  config.after do |example|
    DatabaseCleaner.clean if example.metadata[:type].in?(%i[system feature])
  end

  # Filter slow tests unless explicitly requested
  config.filter_run_excluding :slow unless ENV['RUN_SLOW_TESTS']
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
