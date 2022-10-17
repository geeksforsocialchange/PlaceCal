require 'system_test_helper'

# For system tests so we can test our JS frontend is working
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  Capybara.server = :puma, { Silent: true }
  Selenium::WebDriver.logger.ignore(:browser_options)
end

