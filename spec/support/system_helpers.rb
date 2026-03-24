# frozen_string_literal: true

# Helpers for system specs
module SystemHelpers
  # Navigate to a specific tab in the partner form using daisyUI tabs
  # Uses the aria-label attribute to find the correct tab
  def go_to_partner_tab(tab_label)
    # Wait for form-tabs controller to be initialized
    expect(page).to have_css("[data-controller*='form-tabs']")

    # Find and click the tab by its aria-label
    tab = find("input.tab[aria-label='#{tab_label}']")
    tab.click

    # Wait for the tab panel to be visible (CSS-only via :checked sibling selector)
    tab_hash = tab["data-hash"]
    expect(page).to have_css("[data-section='#{tab_hash}']", visible: true) if tab_hash
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
  end

  # Fill in datatable search and flush the 300ms debounce immediately via JS.
  # This avoids sleeping and makes the search trigger instantly.
  def fill_in_datatable_search(term)
    fill_in "Search...", with: term
    flush_datatable_search_debounce
  end

  # Flush the admin-table controller's search debounce timer so it fires immediately.
  def flush_datatable_search_debounce
    page.execute_script(<<~JS)
      var el = document.querySelector('[data-controller*="admin-table"]');
      var ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, 'admin-table');
      if (ctrl && ctrl.searchDebounceTimer) {
        clearTimeout(ctrl.searchDebounceTimer);
        ctrl.searchTerm = el.querySelector('[data-admin-table-target="search"]').value;
        ctrl.currentPage = 0;
        ctrl.loadData();
      }
    JS
  end

  # Click a radio filter button by its data-filter-column and value
  # This works with the datatable radio button filters (Yes/No style)
  def click_radio_filter(value, column:)
    within("[data-filter-column='#{column}']") do
      click_button value
    end
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
