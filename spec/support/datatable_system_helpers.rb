# frozen_string_literal: true

# Helpers for interacting with admin-table Stimulus datatables in system/feature specs
module DatatableSystemHelpers
  # Wait for Stimulus admin-table to finish loading data
  def await_datatables(time = 10)
    find_element_with_retry do
      expect(page).not_to have_css("[data-admin-table-target='tbody']", text: "Loading data...", wait: time)
      page.find(:css, "[data-admin-table-target='info']", text: /\d+–\d+ of \d+|No records|No entries/, wait: time)
    end
  end

  # Fills in search and flushes the admin-table controller's 300ms debounce via JS
  def fill_in_datatable_search(term)
    fill_in "Search...", with: term
    flush_datatable_search_debounce
  end

  # Flush the debounce timer so search fires immediately without sleeping
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

  # Select a dropdown filter by its data-filter-column attribute
  def select_datatable_filter(value, column:)
    select_element = find("[data-filter-column='#{column}']:not(.hidden)", visible: true, match: :first)
    select_element.select(value)
    select_element.evaluate_script("this.dispatchEvent(new Event('change', { bubbles: true }))")
  end

  # Click a radio filter button (Yes/No style) by its data-filter-column and value
  def click_radio_filter(value, column:)
    within("[data-filter-column='#{column}']") do
      click_button value
    end
  end

  # Wait for admin-table to finish loading after filter/search
  def wait_for_admin_table_load(timeout: 10)
    using_wait_time(timeout) do
      expect(page).not_to have_content("Loading data...")
      expect(page).to have_css("[data-admin-table-target='tbody'] tr", minimum: 1)
    end
  end
end

RSpec.configure do |config|
  config.include DatatableSystemHelpers, type: :system
  config.include DatatableSystemHelpers, type: :feature
end
