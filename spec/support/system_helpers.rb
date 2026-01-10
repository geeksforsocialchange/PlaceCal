# frozen_string_literal: true

# Helpers for system specs
module SystemHelpers
  # Navigate to a specific tab in the partner form using daisyUI tabs
  # Uses the aria-label attribute to find the correct tab
  def go_to_partner_tab(tab_label)
    # Wait for partner-tabs controller to be initialized
    expect(page).to have_css("[data-controller*='partner-tabs']", wait: 10)

    # Find and click the tab by its aria-label
    tab = find("input.tab[aria-label='#{tab_label}']", wait: 10)
    tab.click

    # Wait for the tab content to be visible
    sleep 0.2 # Brief pause for tab switch
  end

  # Named helpers for common form tabs (with emoji icons)
  def go_to_basic_info_tab
    go_to_partner_tab("📋 Basic Info")
  end

  def go_to_place_tab
    go_to_partner_tab("📍 Location")
  end

  def go_to_contact_tab
    go_to_partner_tab("📞 Contact")
  end

  def go_to_tags_tab
    go_to_partner_tab("🏷️ Tags")
  end

  def go_to_calendars_tab
    go_to_partner_tab("📅 Calendars")
  end

  def go_to_admins_tab
    go_to_partner_tab("👥 Admins")
  end

  def go_to_settings_tab
    go_to_partner_tab("⚙ Settings")
  end

  # Click a sidebar navigation link
  def click_sidebar(href)
    within ".sidebar-sticky" do
      link = page.find(:css, "a[href*='#{href}']")
      visit link["href"]
    end
  end

  # Wait for Stimulus admin-table to finish loading data
  def await_datatables(time = 10)
    find_element_with_retry do
      # Wait for loading spinner to disappear
      expect(page).not_to have_css("[data-admin-table-target='tbody']", text: "Loading data...", wait: time)
      # Wait for info to show record count or "No entries"
      page.find(:css, "[data-admin-table-target='info']", text: /\d+–\d+ of \d+|No records|No entries/, wait: time)
    end
  end

  # Retry finding an element (useful for JS-heavy pages)
  def find_element_with_retry(max_attempts: 3)
    attempts = 0
    begin
      yield
    rescue Capybara::ElementNotFound => e
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
    # Brief pause for event dispatch
    sleep 0.1
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
