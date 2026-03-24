# frozen_string_literal: true

# Helpers for interacting with daisyUI tabs in system/feature specs
module TabHelpers
  # Click a tab by its data-hash attribute and wait for the panel to be visible
  def click_tab(hash)
    find("input.tab[data-hash='#{hash}']").click
    expect(page).to have_css("[data-section='#{hash}']", visible: true)
  end

  # Navigate to a partner form tab by its aria-label (includes emoji prefix)
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
end

RSpec.configure do |config|
  config.include TabHelpers, type: :system
  config.include TabHelpers, type: :feature
end
