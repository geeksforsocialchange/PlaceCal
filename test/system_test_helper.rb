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

def find_element_and_retry_if_stale(tries: 0, max_tries: 5)
  tries += 1
  yield
rescue Selenium::WebDriver::Error::StaleElementReferenceError
  unless tries >= max_tries
    sleep 1
    retry
  end
  retry
end

def find_element_and_retry_if_not_found(tries: 0, max_tries: 5)
  tries += 1
  yield
rescue Capybara::ElementNotFound
  unless tries >= max_tries
    sleep 1
    retry
  end
  retry
end

# Dir.glob(File.join(Rails.root, 'test/system/**/*.rb')) do |path|
#  require path
# end
