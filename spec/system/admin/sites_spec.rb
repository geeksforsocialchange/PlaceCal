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

    it "allows adding neighbourhoods via cascading picker", :aggregate_failures do
      click_link "Sites"
      click_link "Add Site"

      # Navigate to Neighbourhoods tab
      click_site_tab "Neighbourhoods"

      # Add additional neighbourhood via nested form
      click_link "Add neighbourhood"

      # Should see cascading neighbourhood controller initialized
      expect(page).to have_css('[data-controller="cascading-neighbourhood"]', wait: 10)

      # The country selector should be present
      within(all('[data-controller="cascading-neighbourhood"]').last) do
        expect(page).to have_css('[data-cascading-neighbourhood-target="country"]')
      end
    end

    it "allows selecting partnerships", :aggregate_failures do
      click_link "Sites"
      click_link "Add Site"

      # Select tags - need to navigate to Partnerships tab
      click_site_tab "Partnerships"
      tags_node = tom_select_node("site_tags")
      tom_select partnership.name, xpath: tags_node.path
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

      # Navigate to Neighbourhoods tab
      find("input.tab[aria-label*='Neighbourhoods']", wait: 10).click

      # The site has a primary neighbourhood (sites_neighbourhood created in setup)
      # Check that the nested form for additional neighbourhoods only has the "Add" button,
      # not any existing neighbourhood cards (since @site only has a primary neighbourhood)
      other_neighbourhoods_section = find(:xpath, "//h2[contains(., 'Other Neighbourhoods')]/ancestor::div[contains(@class, 'card')][1]")

      # Should have the "Add neighbourhood" button
      expect(other_neighbourhoods_section).to have_link("Add neighbourhood")

      # Should NOT have any neighbourhood cards in the "Other neighbourhoods" section
      # (neighbourhood cards have the .nested-fields class)
      expect(other_neighbourhoods_section).not_to have_css(".nested-fields.card")
    end
  end
end
