# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "capybara/rspec"
require "pundit/rspec"
require "view_component/test_helpers"
require "view_component/system_test_helpers"

# Load all support files
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join("spec/fixtures")
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

  # Include ViewComponent test helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  # Include Pundit helpers for helper specs
  config.include Pundit::Authorization, type: :helper

  # Freeze time in tests (matching legacy behavior)
  config.before do
    Timecop.freeze(Time.zone.local(2022, 11, 8))
  end

  config.after do
    Timecop.return
  end

  # Disable transactional fixtures for system/feature tests
  # System tests run in separate threads from the browser - transactions
  # would cause the browser to see uncommitted data, leading to hangs
  config.before(:each, type: :system) do
    self.use_transactional_tests = false
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
    # driven_by is required for Rails system test integration (screenshots, etc.)
    driven_by :cuprite
  end

  config.after(:each, type: :system) do
    DatabaseCleaner.clean
  end

  config.before(:each, type: :feature) do
    self.use_transactional_tests = false
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
  end

  config.after(:each, type: :feature) do
    DatabaseCleaner.clean
  end

  # Filter slow tests unless explicitly requested
  config.filter_run_excluding :slow unless ENV["RUN_SLOW_TESTS"]
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
