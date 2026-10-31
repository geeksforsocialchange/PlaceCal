# frozen_string_literal: true

require "axe-rspec"
require "capybara/playwright"

# axe-rspec auto-includes Axe::Matchers globally via its own RSpec.configure

# The default run drives Selenium directly (timeouts, an extra window); legacy mode only executes scripts, so Playwright can run it.
Axe::Configuration.instance.legacy_mode = true
# Legacy mode's async call, returning plain JSON; the driver's evaluate_async_script walks axe's huge result handle and stalls.
Capybara::Playwright::Driver.define_method(:execute_async_script) do |script, *args|
  with_playwright_page do |page|
    page.evaluate("(args) => new Promise((resolve) => (function() { #{script} }).apply(window, [...args, resolve]))", arg: args)
  end
end

# axe files text over a background image or under an overlapping element as incomplete, which be_axe_clean passes.
# This measures that text against the nearest solid fill behind it. Use after be_axe_clean, which loads axe.
UNRESOLVED_LOW_CONTRAST = File.read(File.join(__dir__, "unresolved_low_contrast.js")).delete_prefix("export default ")

RSpec::Matchers.define :have_no_unresolved_low_contrast do
  match do |page|
    @failures = page.driver.with_playwright_page { |pw| pw.evaluate(UNRESOLVED_LOW_CONTRAST) }
    @failures.empty?
  end

  failure_message { "expected no low-contrast text axe left unresolved, found:\n#{@failures.join("\n")}" }
end
