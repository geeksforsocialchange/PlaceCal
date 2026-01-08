# frozen_string_literal: true

# Helpers for system specs
module SystemHelpers
  # Click a sidebar navigation link
  def click_sidebar(href)
    within ".sidebar-sticky" do
      link = page.find(:css, "a[href*='#{href}']")
      visit link["href"]
    end
  end

  # Wait for datatables to load
  # Supports both old DataTables (#datatable_info) and new Stimulus admin-table
  def await_datatables(time = 5)
    find_element_with_retry do
      # Try new Stimulus admin-table first, then fall back to legacy DataTables
      if page.has_css?("[data-admin-table-target='info']", wait: 1)
        page.find(:css, "[data-admin-table-target='info']", text: /Showing|No entries/, wait: time)
      else
        page.find(:css, "#datatable_info", wait: time)
      end
    end
  end

  # Retry finding an element (useful for JS-heavy pages)
  def find_element_with_retry(max_attempts: 3)
    attempts = 0
    begin
      yield
    rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::StaleElementReferenceError => e
      attempts += 1
      retry if attempts < max_attempts
      raise e
    end
  end

  # Suppress stdout during block execution
  def suppress_stdout
    stdout = $stdout
    $stdout = File.open(File::NULL, "w")
    yield
  ensure
    $stdout = stdout
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
  config.include SystemHelpers, type: :feature
end
