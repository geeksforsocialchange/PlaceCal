# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Calendars", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }

  describe "select2 inputs on calendar form" do
    it "allows selecting partner organiser and default location", :vcr do
      # Stub calendar source validation to avoid HTTP requests
      allow_any_instance_of(Calendar).to receive(:check_source_reachable).and_return(true)

      click_link "Calendars"
      await_datatables

      click_link "Add New Calendar"

      # Select partner organiser
      partner_organiser = select2_node("calendar_partner")
      select2 partner.name, xpath: partner_organiser.path
      assert_select2_single partner.name, partner_organiser

      # Select default location
      default_location = select2_node("calendar_place")
      select2 partner_two.name, xpath: default_location.path
      assert_select2_single partner_two.name, default_location

      fill_in "Name", with: "Test Calendar"
      fill_in "URL", with: "https://www.eventbrite.co.uk/o/test-org-12345"

      click_button "Create Calendar"

      # Verify data persists
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      partner_organiser = select2_node("calendar_partner")
      assert_select2_single partner.name, partner_organiser

      default_location = select2_node("calendar_place")
      assert_select2_single partner_two.name, default_location
    end
  end
end
