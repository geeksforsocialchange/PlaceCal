# frozen_string_literal: true

require "capybara/rails"
require "capybara/rspec"
require "selenium-webdriver"

# Disable CSS animations for faster, more reliable tests
Capybara.disable_animation = true

# Configure default host for system tests
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
  config.always_include_port = true
end

# Use lvh.me for subdomain testing (resolves to 127.0.0.1)
# app_host: URL the browser uses to access the app (supports subdomains)
# server_host: Where Puma binds - must be 127.0.0.1 for CI compatibility
Capybara.app_host = "http://lvh.me"
Capybara.server_host = "127.0.0.1"

RSpec.configure do |config|
  # Clean up after each system test
  config.after(type: :system) do
    Capybara.reset_sessions!
  end

  # Filter Selenium from backtraces
  config.filter_gems_from_backtrace("capybara", "selenium-webdriver")
end
