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

  # Wait for page to settle after JavaScript actions
  def wait_for_page_load
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script("document.readyState") == "complete"
    end
  rescue Timeout::Error
    # Page didn't fully load, continue anyway
  end
end

World(CucumberHelpers)
