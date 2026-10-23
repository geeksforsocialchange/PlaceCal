# frozen_string_literal: true

require "capybara/playwright"

# The visual regression run points this at the current checkout's binary when it captures a base commit.
PLAYWRIGHT_CLI = ENV.fetch("PLAYWRIGHT_CLI_EXECUTABLE_PATH") { Rails.root.join("node_modules/.bin/playwright").to_s }

%i[chromium webkit].each do |browser_type|
  Capybara.register_driver(:"playwright_#{browser_type}") do |app|
    Capybara::Playwright::Driver.new(
      app,
      browser_type:,
      headless: true,
      playwright_cli_executable_path: PLAYWRIGHT_CLI,
      viewport: { width: 1250, height: 900 },
      deviceScaleFactor: 1,
      reducedMotion: "reduce",
      locale: "en-GB",
      timezoneId: "Europe/London"
    )
  end
end
