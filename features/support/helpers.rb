# frozen_string_literal: true

# Helper module for Cucumber steps
module CucumberHelpers
  # Create the default site required for URL routing
  def create_default_site
    create(:site, slug: 'default-site') unless Site.exists?(slug: 'default-site')
  end

  # Wait for datatables to load
  def await_datatables(time = 5)
    page.find(:css, '#datatable_info', wait: time)
  rescue Capybara::ElementNotFound
    # DataTables not present on this page
  end

  # Wait for page to settle after JavaScript actions
  def wait_for_page_load
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('document.readyState') == 'complete'
    end
  rescue Timeout::Error
    # Page didn't fully load, continue anyway
  end
end

World(CucumberHelpers)
