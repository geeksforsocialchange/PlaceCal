# frozen_string_literal: true

require "rails_helper"

# Exercises the JS-driven neighbourhood cascade end to end: selecting a level
# auto-submits and filters the partner list, and drilling reveals the next
# level. This lives in a system spec because it depends on the custom-select and
# neighbourhood-cascade Stimulus controllers running in a real browser.
RSpec.describe "Directory partner filtering", :slow, type: :system do
  let!(:default_site) { create(:default_site) }

  # Two partners in different regions so filtering by one is observable.
  let(:northvale_ward) { create(:riverside_ward) }
  let(:southmere_ward) { create(:cliffside_ward) }

  let!(:northern_partner) do
    create(:partner, name: "Northern Partner", address: create(:address, neighbourhood: northvale_ward))
  end
  let!(:southern_partner) do
    create(:partner, name: "Southern Partner", address: create(:address, neighbourhood: southmere_ward))
  end

  it "filters partners by neighbourhood and reveals the next level on selection" do
    visit public_url("/partners")

    expect(page).to have_content("Northern Partner")
    expect(page).to have_content("Southern Partner")

    within("[data-controller='neighbourhood-cascade']") do
      find("[data-custom-select-target='trigger']").click
      click_button("Northvale (1)")
    end

    # The selection auto-applied: only the Northvale partner remains...
    expect(page).to have_content("Northern Partner")
    expect(page).to have_no_content("Southern Partner")
    # ...and the cascade drilled in, offering the region's subtree.
    expect(page).to have_button("All of Northvale")
  end
end
