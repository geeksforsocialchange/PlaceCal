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

  # Select a filter value by its data-filter-column attribute
  # This works with the datatable dropdown filters that don't have labels
  def select_datatable_filter(value, column:)
    select_element = find("[data-filter-column='#{column}']:not(.hidden)", visible: true, match: :first)
    select_element.select(value)
    # Trigger change event to ensure Stimulus controller handles it
    select_element.evaluate_script("this.dispatchEvent(new Event('change', { bubbles: true }))")
    # Wait for AJAX to start and complete
    sleep 0.3
  end

  # Wait for admin-table datatable to finish loading after filter/search
  def wait_for_admin_table_load(timeout: 10)
    # Wait for loading spinner to disappear (if shown) and content to load
    using_wait_time(timeout) do
      expect(page).not_to have_content("Loading data...")
      expect(page).to have_css("[data-admin-table-target='tbody'] tr", minimum: 1)
    end
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
  config.include SystemHelpers, type: :feature
end
