# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Calendars", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }

  describe "tom-select inputs on calendar edit form" do
    let!(:calendar) { create(:calendar, partner: partner, name: "Test Calendar") }

    it "allows changing partner organiser", :aggregate_failures do
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Partner organiser is on Source tab (default)
      expect(page).to have_content("Source")

      # Select a different partner using Tom Select
      partner_select_fieldset = find("fieldset", text: "Partner Organiser")
      partner_ts_wrapper = partner_select_fieldset.find(".ts-wrapper")
      tom_select partner_two.name, xpath: partner_ts_wrapper.path

      click_button "Save"

      # Verify success
      expect(page).to have_selector("[role='alert'].bg-green-50, .alert-success", wait: 10)

      # Verify data persists by re-editing
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Check partner changed
      partner_select = find("#calendar_partner_id", visible: :all)
      expect(partner_select.value).to eq(partner_two.id.to_s)
    end

    it "allows changing default location", :aggregate_failures do
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Navigate to Location tab
      find('input[data-hash="location"]').click

      # Wait for tab content
      expect(page).to have_content("Default Location", wait: 5)

      # Select default location using Tom Select
      place_select_fieldset = find("fieldset", text: "Default Location")
      place_ts_wrapper = place_select_fieldset.find(".ts-wrapper")
      tom_select partner_two.name, xpath: place_ts_wrapper.path

      click_button "Save"

      # Verify success
      expect(page).to have_selector("[role='alert'].bg-green-50, .alert-success", wait: 10)

      # Verify data persists by re-editing
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Navigate to Location tab and check default location
      find('input[data-hash="location"]').click
      place_select = find("#calendar_place_id", visible: :all)
      expect(place_select.value).to eq(partner_two.id.to_s)
    end
  end
end
