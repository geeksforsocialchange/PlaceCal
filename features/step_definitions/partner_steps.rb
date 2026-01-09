# frozen_string_literal: true

# Step definitions for partner management

Given("there is a partner called {string}") do |name|
  @partner = create(:partner, name: name)
end

Given("there is a partner called {string} in {string}") do |name, ward_name|
  ward = Neighbourhood.find_by(name: ward_name) || create(:neighbourhood, name: ward_name)
  address = create(:address, neighbourhood: ward)
  @partner = create(:partner, name: name, address: address)
end

Given("the following partners exist:") do |table|
  table.hashes.each do |row|
    create(:partner, name: row["name"], summary: row["summary"])
  end
end

When("I visit the partners page") do
  create_default_site
  visit "/partners"
end

When("I create a new partner with name {string}") do |name|
  # Ensure we have neighbourhoods for the geocoder
  create(:riverside_ward) unless Neighbourhood.exists?(name: "Riverside")

  click_link "Partners"
  await_datatables
  click_link "Add Partner"
  fill_in "Name", with: name

  # Fill in address (required - partner needs address or service area)
  fill_in "Street address", with: "123 Main Street"
  fill_in "City", with: "Millbrook"
  fill_in "Postcode", with: "ZZMB 1RS"

  # Wait for any async validation to complete
  sleep 0.3
  click_button "Save and continue..."
end

When("I edit the partner {string}") do |name|
  click_link "Partners"
  await_datatables
  click_link name
end

When("I update the partner summary to {string}") do |summary|
  # Find summary field by fieldset legend (daisyUI pattern)
  fieldset = page.find("fieldset", text: "Summary")
  input = fieldset.find("textarea")
  input.set(summary)
  click_button "Save"
end

Then("I should see the partner {string} in the list") do |name|
  click_link "Partners"
  await_datatables
  expect(page).to have_content(name)
end

Then("the partner {string} should have summary {string}") do |name, summary|
  partner = Partner.find_by(name: name)
  expect(partner.summary).to eq(summary)
end
