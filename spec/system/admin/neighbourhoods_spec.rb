# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Neighbourhoods", :slow, type: :system do
  include_context "admin login"

  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:riverside_ward) { create(:riverside_ward) }

  describe "tom-select inputs on neighbourhood form" do
    it "allows selecting users", :aggregate_failures do
      click_link "Neighbourhoods"
      await_datatables

      # Click the first neighbourhood name in the table
      within "[data-admin-table-target='tbody']" do
        first("a").click
      end

      click_link "Edit"

      # Select users
      users_node = tom_select_node("neighbourhood_users")
      tom_select admin_user.to_s, neighbourhood_admin.to_s, xpath: users_node.path
      assert_tom_select_multiple [admin_user.to_s, neighbourhood_admin.to_s], users_node

      click_button "Save"

      # Navigate back to verify data persists
      click_link "Neighbourhoods"
      await_datatables

      within "[data-admin-table-target='tbody']" do
        first("a").click
      end

      find_element_and_retry_if_not_found do
        click_link "Edit"
      end

      find_element_and_retry_if_stale do
        find_element_and_retry_if_not_found do
          users_node = tom_select_node("neighbourhood_users")
          assert_tom_select_multiple [admin_user.to_s, neighbourhood_admin.to_s], users_node
        end
      end
    end
  end
end
