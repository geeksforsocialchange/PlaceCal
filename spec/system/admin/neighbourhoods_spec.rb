# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Neighbourhoods", :slow, type: :system do
  include_context "admin login"

  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:riverside_ward) { create(:riverside_ward) }

  describe "stacked list selector on neighbourhood form" do
    it "allows selecting users", :aggregate_failures do
      click_link "Neighbourhoods"
      await_datatables

      # Click the first neighbourhood name in the table
      within "[data-admin-table-target='tbody']" do
        first("a").click
      end

      click_link "Edit"

      # Find the stacked list selector and its tom-select dropdown
      within ".neighbourhood_users" do
        # Add users via the tom-select dropdown (click on ts-control, not the hidden select)
        find(".ts-control").click
        find(".ts-dropdown .option", text: admin_user.to_s).click

        find(".ts-control").click
        find(".ts-dropdown .option", text: neighbourhood_admin.to_s).click

        # Verify users appear in the stacked list
        expect(page).to have_selector("[data-item-name]", count: 2)
        expect(page).to have_selector("[data-item-name='#{admin_user.name}']")
        expect(page).to have_selector("[data-item-name='#{neighbourhood_admin.name}']")
      end

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
        within ".neighbourhood_users" do
          expect(page).to have_selector("[data-item-name]", count: 2)
          expect(page).to have_selector("[data-item-name='#{admin_user.name}']")
          expect(page).to have_selector("[data-item-name='#{neighbourhood_admin.name}']")
        end
      end
    end
  end
end
