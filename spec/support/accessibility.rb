# frozen_string_literal: true

require "axe-rspec"
require "capybara/playwright"

# axe-rspec auto-includes Axe::Matchers globally via its own RSpec.configure

# The default run drives Selenium directly (timeouts, an extra window); legacy mode only executes scripts, so Playwright can run it.
Axe::Configuration.instance.legacy_mode = true
# Legacy mode's async call, returning plain JSON; the driver's evaluate_async_script walks axe's huge result handle and stalls.
Capybara::Playwright::Driver.define_method(:execute_async_script) do |script, *args|
  with_playwright_page do |page|
    # A JSON round trip turns rule options like checking_only's symbols into values Playwright can pass
    page.evaluate("(args) => new Promise((resolve) => (function() { #{script} }).apply(window, [...args, resolve]))",
                  arg: JSON.parse(args.to_json))
  end
end
