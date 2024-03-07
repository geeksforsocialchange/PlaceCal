# frozen_string_literal: true

require 'test_helper'

Capybara.app_host = 'http://lvh.me'
Capybara.default_max_wait_time = 60

VCR.configure do |c|
  c.ignore_localhost = true
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      args: %w[headless enable-features=NetworkService,NetworkServiceInProcess]
    }
  )

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities
end

# Dir.glob(File.join(Rails.root, 'test/system/**/*.rb')) do |path|
#  require path
# end
