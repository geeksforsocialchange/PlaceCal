require 'test_helper'

Capybara.app_host = 'http://lvh.me'
VCR.turn_off!
WebMock.allow_net_connect!

# For system tests so we can test our JS frontend is working
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
end

