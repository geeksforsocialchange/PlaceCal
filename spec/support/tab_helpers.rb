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
    return if page.has_css?("input.tab[aria-label='#{tab_label}']:checked", wait: 5)

    # DIAGNOSTIC (ci/repro-flaky-system-tests branch only): dump the exact state
    # at the moment the tab switch fails, so the CI repro can pin the mechanism.
    diag =
      begin
        page.evaluate_script(<<~JS)
          (() => {
            const app = window.Stimulus || window.application;
            const sb = document.querySelector('[data-controller~="save-bar"]');
            const ctrl = sb && app.getControllerForElementAndIdentifier(sb, 'save-bar');
            const checked = document.querySelector('input.tab[name="partner_tabs"]:checked');
            return JSON.stringify({
              dirty: ctrl ? ctrl.dirty : 'no-ctrl',
              checkedTab: checked ? checked.getAttribute('aria-label') : 'none',
              hash: location.hash,
              ftConnected: !!document.querySelector('[data-form-tabs-connected]'),
              sbConnected: !!document.querySelector('[data-save-bar-connected]'),
              ssKeys: Object.keys(window.sessionStorage),
              consoleErrs: (window.__consoleErrors || [])
            });
          })()
        JS
      rescue StandardError => e
        "diag-eval-failed: #{e.class}: #{e.message}"
      end
    raise "TAB SWITCH FAILED for #{tab_label} :: #{diag}"
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
