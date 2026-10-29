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

Capybara.register_driver(:playwright_system) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    playwright_cli_executable_path: PLAYWRIGHT_CLI,
    viewport: { width: 1400, height: 1400 }
  )
end

# A trace of every system example, kept only when it fails; open with `yarn playwright show-trace <zip>`.
module PlaywrightTrace
  DIR = Rails.root.join("tmp/playwright-traces")

  module_function

  def start(page, example)
    page.driver.start_tracing(screenshots: true, snapshots: true, sources: true, title: example.full_description)
    example.metadata[:playwright_trace_driver] = page.driver
  end

  # Stops on the driver the trace started on, in case the example switched drivers.
  def stop(example)
    driver = example.metadata.delete(:playwright_trace_driver) or return

    path = (DIR.join("#{example.id.parameterize}.zip").to_s if example.exception)
    driver.stop_tracing(path:)
    warn "[playwright-trace] #{path}" if path
  rescue StandardError => e
    warn "[playwright-trace] not saved: #{e.class}: #{e.message}".truncate(300)
  end
end
