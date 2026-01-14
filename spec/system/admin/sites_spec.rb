# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Sites", :slow, type: :system do
  include_context "admin login"

  let!(:partnership) { create(:partnership) }
  let!(:site) { create(:site) }
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }
  let!(:sites_neighbourhood) do
    create(:sites_neighbourhood, site: site, neighbourhood: riverside_ward)
  end

  describe "tom-select inputs on site form" do
    # Helper to click site form tabs (daisyUI radio tab inputs)
    # Accepts any unsaved changes confirmation that may appear
    def click_site_tab(tab_name)
      begin
        accept_confirm do
          find("input.tab[aria-label*='#{tab_name}']", wait: 10).click
        end
      rescue Capybara::ModalNotFound
        # No confirmation dialog appeared, which is fine
      end
      sleep 0.2
    end

    it "allows selecting neighbourhoods and tags", :aggregate_failures do
      pending "TODO: Fix cascading neighbourhood AJAX test setup"
      click_link "Sites"
      click_link "Add Site"

      # Site admin uses plain select with "First Last (email)" format
      admin_label = "#{admin_user.first_name} #{admin_user.last_name} (#{admin_user.email})"
      select admin_label, from: "site_site_admin_id"

      # Navigate to Neighbourhoods tab
      click_site_tab "Neighbourhoods"

      # Select primary neighbourhood (only appears when creating a site)
      neighbourhood_main = tom_select_node("site_sites_neighbourhood_neighbourhood_id")
      tom_select riverside_ward.name, xpath: neighbourhood_main.path
      assert_tom_select_single riverside_ward.name, neighbourhood_main

      # Add additional neighbourhood via nested form
      click_link "Add neighbourhood"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      tom_select oldtown_ward.name, xpath: service_areas[-1].path
      assert_tom_select_single oldtown_ward.name, service_areas[0]

      # Select tags - need to navigate to Partnerships tab
      click_site_tab "Partnerships"
      tags_node = tom_select_node("site_tags")
      tom_select partnership.name, xpath: tags_node.path
      assert_tom_select_multiple [partnership.name_with_type], tags_node

      # Navigate back to Basic Info and fill required fields
      click_site_tab "Basic Info"
      fill_in "site_name", with: "Test Site"

      # URL and Slug are on Admin tab
      click_site_tab "Admin"
      fill_in "site_url", with: "https://test.com"
      fill_in "site_slug", with: "test-site"

      click_button "Save"

      # Verify data persists
      click_link "Sites"
      click_link "Test Site"

      # Site admin is plain select with "First Last (email)" format
      expect(page).to have_select("site_site_admin_id", selected: admin_label)

      # Navigate to Neighbourhoods tab to check neighbourhoods
      click_site_tab "Neighbourhoods"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      assert_tom_select_single oldtown_ward.name, service_areas[0]

      # Navigate to Partnerships tab to check tags
      click_site_tab "Partnerships"
      tags_node = tom_select_node("site_tags")
      assert_tom_select_multiple [partnership.name_with_type], tags_node
    end
  end

  describe "primary neighbourhood rendering" do
    it "does not render primary neighbourhood in other neighbourhoods section" do
      click_link "Sites"
      await_datatables

      click_link site.name

      # Wait for the page to load
      find("button", text: "Save", wait: 5)

      # The primary neighbourhood should not appear in the sites_neighbourhoods section
      service_areas = all(:css, ".sites_neighbourhoods .ts-wrapper", wait: 1)

      expect(service_areas.length).to be_zero,
                                      "@site should only have a primary neighbourhood, " \
                                      "if this fails either this is now rendering where " \
                                      "it shouldn't or another neighborhood has been added " \
                                      "at setup and the test should be adjusted"
    end
  end
end
