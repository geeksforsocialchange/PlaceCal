# frozen_string_literal: true

# Helper module for Cucumber steps
module CucumberHelpers
  # Create the default site required for URL routing
  def create_default_site
    create(:site, slug: "default-site") unless Site.exists?(slug: "default-site")
  end

  # Wait for Stimulus admin-table to finish loading data
  def await_datatables(time = 5)
    # Wait for loading to complete and info to show record count
    expect(page).not_to have_css("[data-admin-table-target='tbody']", text: "Loading data...", wait: time)
    page.find(:css, "[data-admin-table-target='info']", text: /\d+–\d+ of \d+|No records|No entries/, wait: time)
  rescue Capybara::ElementNotFound
    # Admin table not present on this page
  end

  # Fill in datatable search and flush the 300ms debounce immediately via JS.
  def fill_in_datatable_search(term)
    search_input = find('input[data-admin-table-target="search"]')
    search_input.fill_in(with: term)
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

  # Wait for page to settle after JavaScript actions
  def wait_for_page_load
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script("document.readyState") == "complete"
    end
  rescue Timeout::Error
    # Page didn't fully load, continue anyway
  end

  # Fill in a field by finding its fieldset legend (daisyUI pattern)
  def fill_in_fieldset(legend_text, with:)
    # First try standard fill_in (works with label, name, or id)
    fill_in legend_text, with: with
  rescue Capybara::ElementNotFound
    # Fall back to finding by fieldset legend
    fieldsets = page.all("fieldset").select do |fs|
      legend = fs.first("legend")
      next false unless legend

      legend_text_actual = legend.text.strip
      legend_text_actual == legend_text ||
        legend_text_actual.start_with?(legend_text) ||
        legend_text_actual.downcase.include?(legend_text.downcase)
    end

    fieldset = fieldsets.find { |fs| fs.first("legend")&.text&.strip == legend_text }
    fieldset ||= fieldsets.first

    raise Capybara::ElementNotFound, "Could not find fieldset for '#{legend_text}'" unless fieldset

    input = fieldset.find("input, textarea, select", match: :first)
    input.set(with)
  end
end

World(CucumberHelpers)
