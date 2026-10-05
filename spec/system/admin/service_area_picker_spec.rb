# frozen_string_literal: true

require "rails_helper"

# Regression coverage for the cascading neighbourhood picker's auto-select.
# With a single country the picker auto-selects it, and it used to dead-end
# there: it loaded the next level from the (null) parent scope instead of the
# auto-selected country, so the endpoint returned top-level roots and every
# level below stayed empty. The picker was unusable on single-country data.
RSpec.describe "Service area cascading picker", :slow, type: :system do
  include_context "admin login"

  # A single, clean country -> region -> county -> district -> wards tree, so
  # every level above "ward" has exactly one option and auto-selects, and the
  # ward dropdown is only reachable if the cascade does not dead-end.
  let!(:country) { create(:normal_island_country) }
  let!(:region) { create(:northvale_region, parent: country) }
  let!(:county) { create(:greater_millbrook_county, parent: region) }
  let!(:district) { create(:millbrook_district, parent: county) }
  let!(:riverside_ward) { create(:riverside_ward, parent: district) }
  let!(:oldtown_ward) { create(:oldtown_ward, parent: district) }

  it "auto-selects the single country and cascades down to the ward dropdown", :aggregate_failures do
    click_link "Partners"
    await_datatables
    click_link "Add Partner"

    fill_in "partner_name", with: "Auto Select Test Partner"
    expect(page).to have_content("This name is available!")
    click_button "Continue"

    expect(page).to have_content("Set Location")
    click_link "Add Service Area"

    within(all("[data-controller='cascading-neighbourhood']").last) do
      ward_select = find("[data-cascading-neighbourhood-target='ward']")

      # The wards under the auto-selected chain populate the ward dropdown.
      # (Fetches are chained across five levels, so allow extra wait time.)
      using_wait_time(15) do
        expect(ward_select).to have_css("option", text: "Riverside")
        expect(ward_select).to have_css("option", text: "Oldtown")
      end

      ward_select.find(:option, "Riverside").select_option
      expect(find("input[name*='neighbourhood_id']", visible: false).value).to eq(riverside_ward.id.to_s)
    end
  end
end
