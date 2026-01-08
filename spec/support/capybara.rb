# frozen_string_literal: true

require "capybara/rails"
require "capybara/rspec"
require "capybara/cuprite"

# Disable CSS animations for faster, more reliable tests
Capybara.disable_animation = true

# Register Cuprite driver - pure Ruby driver using Chrome DevTools Protocol
# More reliable than Selenium, no separate chromedriver needed
Capybara.register_driver :cuprite do |app|
  browser_opts = {}

  # CI/Docker environments need additional Chrome flags
  if ENV["DOCKER"] || ENV["CI"]
    browser_opts = {
      "no-sandbox" => nil,
      "disable-gpu" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-software-rasterizer" => nil
    }
  end

  options = {
    window_size: [1400, 1400],
    js_errors: true,
    headless: ENV.fetch("HEADLESS", "true") != "false",
    slowmo: ENV["SLOWMO"]&.to_f,
    process_timeout: 30,
    timeout: 15,
    browser_options: browser_opts
  }
  # Use explicit Chrome path if provided (e.g., from GitHub Actions)
  options[:browser_path] = ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"].present?

  Capybara::Cuprite::Driver.new(app, **options)
end

Capybara.javascript_driver = :cuprite

# Configure default host for system tests
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
  config.always_include_port = true
end

# Use lvh.me for subdomain testing (resolves to 127.0.0.1)
Capybara.app_host = "http://lvh.me"
Capybara.server_host = "lvh.me"

RSpec.configure do |config|
  config.before(type: :system) do
    driven_by :cuprite
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
      host: "lvh.me",
      port: port,
      protocol: "http"
    }
    # Also update Rails routes default URL options for consistency
    Rails.application.routes.default_url_options = {
      host: "lvh.me",
      port: port,
      protocol: "http"
    }
  end

  # Clean up after each system test
  config.after(type: :system) do
    Capybara.reset_sessions!
  end

  # Filter Cuprite/Ferrum from backtraces
  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
