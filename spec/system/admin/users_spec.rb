# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Users", :slow, type: :system do
  include_context "admin login"

  # Create wards first to avoid duplicates
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }
  let!(:neighbourhood_admin) { create(:neighbourhood_admin, neighbourhood: riverside_ward) }
  let!(:partner) { create(:riverside_community_hub, address: create(:address, neighbourhood: riverside_ward)) }
  let!(:partner_admin) { create(:partner_admin, partner: partner) }
  let!(:partner_two) { create(:oldtown_library, address: create(:address, neighbourhood: oldtown_ward)) }
  let!(:partnership) { create(:partnership) }

  describe "stacked list selectors on users form" do
    it "allows selecting partners, neighbourhoods and tags", :aggregate_failures do
      click_link "Users"
      await_datatables

      # Edit a root user (has access to all potential stacked list selectors)
      # Click on the admin user's full name to edit (datatable shows "FirstName LastName")
      full_name = [admin_user.first_name, admin_user.last_name].compact.join(" ")
      click_link full_name

      # Navigate to Permissions tab where stacked list selectors are located
      find('input[data-hash="permissions"]').click

      # Select partners using stacked list selector
      stacked_list_select partner.name, partner_two.name, wrapper_class: "user_partners"
      # Stacked list shows plain names, not formatted dropdown text
      assert_stacked_list_items [partner.name, partner_two.name], "user_partners"

      # Select neighbourhoods (dropdown shows "Name (Unit)" but list shows just name)
      stacked_list_select riverside_ward.name, oldtown_ward.name, wrapper_class: "user_neighbourhoods"
      assert_stacked_list_items [riverside_ward.name, oldtown_ward.name], "user_neighbourhoods"

      # Select partnerships (dropdown shows "Type: Name" but list shows just name)
      stacked_list_select partnership.name, wrapper_class: "user_tags"
      assert_stacked_list_items [partnership.name], "user_tags"

      click_button "Save"

      # Return to user to verify data persists
      click_link "Users"
      await_datatables

      find_element_and_retry_if_stale do
        click_link full_name
      end

      # Navigate to Permissions tab again
      find('input[data-hash="permissions"]').click

      assert_stacked_list_items [partner.name, partner_two.name], "user_partners"
      assert_stacked_list_items [riverside_ward.name, oldtown_ward.name], "user_neighbourhoods"
      assert_stacked_list_items [partnership.name], "user_tags"
    end
  end
end
