# frozen_string_literal: true

require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-dev-shm-usage')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

# Configure default host for system tests
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
  config.always_include_port = true
end

# Use lvh.me for subdomain testing (resolves to 127.0.0.1)
Capybara.app_host = 'http://lvh.me'
Capybara.server_host = 'lvh.me'

RSpec.configure do |config|
  config.before(type: :system) do
    driven_by :headless_chrome
  end

  # Reset Capybara session before each system test to ensure clean state
  config.before(type: :system) do
    Capybara.reset_sessions!
  end

  # Configure ActionMailer to use Capybara's dynamic server port
  # This ensures email links (password reset, invitation) point to the correct host:port
  config.before(type: :system) do
    port = Capybara.current_session.server.port
    ActionMailer::Base.default_url_options = {
      host: 'lvh.me',
      port: port,
      protocol: 'http'
    }
    # Also update Rails routes default URL options for consistency
    Rails.application.routes.default_url_options = {
      host: 'lvh.me',
      port: port,
      protocol: 'http'
    }
  end

  # Clean up after each system test
  config.after(type: :system) do
    Capybara.reset_sessions!
  end
end
