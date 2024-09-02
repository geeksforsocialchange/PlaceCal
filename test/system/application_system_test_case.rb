# frozen_string_literal: true

require 'system_test_helper'
require 'selenium/webdriver'

# For system tests so we can test our JS frontend is working
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  Capybara.server = :puma, { Silent: true }
  Selenium::WebDriver.logger.ignore(:browser_options)

  # TODO: Remove this hack
  # Currently, the first test is always failing as the webserver isn't loaded yet.
  # This gives it a kick to get it up and running.
  setup do
    visit '/'
  end
end
