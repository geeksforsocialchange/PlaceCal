# frozen_string_literal: true

# Helpers for interacting with daisyUI tabs in system/feature specs
module TabHelpers
  # Wait for the form-tabs Stimulus controller to be connected, not just for
  # the data-controller attribute (present in the raw HTML before JS boots).
  # Clicking a tab before connect() can be silently reverted by
  # restoreTabAfterSave().
  def wait_for_form_tabs
    expect(page).to have_css("[data-form-tabs-connected]")
  end

  # Wait for the save-bar Stimulus controller to be connected. Button
  # visibility only updates via listeners attached in its connect().
  def wait_for_save_bar
    expect(page).to have_css("[data-save-bar-connected]")
  end

  # Click a tab by its data-hash attribute and wait for it to be selected.
  # Uses a retryable CSS selector for the assertion instead of checking the
  # already-resolved element — avoids CI flakiness where the checked state
  # lags behind the click in headless Chrome.
  def click_tab(hash)
    wait_for_form_tabs
    find("input.tab[data-hash='#{hash}']").click
    expect(page).to have_css("input.tab[data-hash='#{hash}']:checked", wait: 5)
  end

  # Navigate to a partner form tab by its aria-label (includes emoji prefix)
  def go_to_partner_tab(tab_label)
    wait_for_form_tabs
    find("input.tab[aria-label='#{tab_label}']").click
    expect(page).to have_css("input.tab[aria-label='#{tab_label}']:checked", wait: 5)
  end

  def go_to_basic_info_tab = go_to_partner_tab("📋 Basic Info")
  def go_to_place_tab = go_to_partner_tab("📍 Location")
  def go_to_contact_tab = go_to_partner_tab("📞 Contact")
  def go_to_tags_tab = go_to_partner_tab("🏷️ Tags")
  def go_to_calendars_tab = go_to_partner_tab("📅 Calendars")
  def go_to_admins_tab = go_to_partner_tab("👥 Admins")
  def go_to_settings_tab = go_to_partner_tab("⚙ Settings")
end

RSpec.configure do |config|
  config.include TabHelpers, type: :system
  config.include TabHelpers, type: :feature
end
