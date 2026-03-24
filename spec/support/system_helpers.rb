# frozen_string_literal: true

# Helpers for system specs
module SystemHelpers # rubocop:disable Metrics/ModuleLength
  def admin_url(path)
    port = Capybara.current_session.server.port
    "http://admin.lvh.me:#{port}#{path}"
  end

  def public_url(path)
    port = Capybara.current_session.server.port
    "http://lvh.me:#{port}#{path}"
  end

  # Named sign_in_as to avoid collision with Warden::Test::Helpers#login_as
  def sign_in_as(user)
    visit admin_url("/users/sign_in")
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
  end

  def assert_has_flash(type, message = nil)
    alert_class = type == :success ? "alert-success" : "alert-error"
    selector = "[role='alert'].#{alert_class}, .flashes .alert-#{type}"
    if message
      expect(page).to have_css(selector, text: message)
    else
      expect(page).to have_css(selector)
    end
  end

  def click_tab(hash)
    find("input.tab[data-hash='#{hash}']").click
    expect(page).to have_css("[data-section='#{hash}']", visible: true)
  end

  def go_to_partner_tab(tab_label)
    expect(page).to have_css("[data-controller*='form-tabs']")
    tab = find("input.tab[aria-label='#{tab_label}']")
    tab.click
    tab_hash = tab["data-hash"]
    expect(page).to have_css("[data-section='#{tab_hash}']", visible: true) if tab_hash
  end

  def go_to_basic_info_tab = go_to_partner_tab("📋 Basic Info")
  def go_to_place_tab = go_to_partner_tab("📍 Location")
  def go_to_contact_tab = go_to_partner_tab("📞 Contact")
  def go_to_tags_tab = go_to_partner_tab("🏷️ Tags")
  def go_to_calendars_tab = go_to_partner_tab("📅 Calendars")
  def go_to_admins_tab = go_to_partner_tab("👥 Admins")
  def go_to_settings_tab = go_to_partner_tab("⚙ Settings")

  def click_sidebar(href)
    within ".sidebar-sticky" do
      link = page.find(:css, "a[href*='#{href}']")
      visit link["href"]
    end
  end

  def await_datatables(time = 10)
    find_element_with_retry do
      expect(page).not_to have_css("[data-admin-table-target='tbody']", text: "Loading data...", wait: time)
      page.find(:css, "[data-admin-table-target='info']", text: /\d+–\d+ of \d+|No records|No entries/, wait: time)
    end
  end

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

  def suppress_stdout
    stdout = $stdout
    $stdout = File.open(File::NULL, "w")
    yield
  ensure
    $stdout = stdout
  end

  def select_datatable_filter(value, column:)
    select_element = find("[data-filter-column='#{column}']:not(.hidden)", visible: true, match: :first)
    select_element.select(value)
    select_element.evaluate_script("this.dispatchEvent(new Event('change', { bubbles: true }))")
  end

  # Fills in search and flushes the admin-table controller's 300ms debounce via JS
  def fill_in_datatable_search(term)
    fill_in "Search...", with: term
    flush_datatable_search_debounce
  end

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

  def click_radio_filter(value, column:)
    within("[data-filter-column='#{column}']") do
      click_button value
    end
  end

  def wait_for_admin_table_load(timeout: 10)
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
