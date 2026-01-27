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

  # Step 1: Name - wizard form uses partner_wizard controller
  fill_in "partner_name", with: name

  # Wait for name validation debounce to complete
  sleep 0.5
  click_button "Continue"

  # Step 2: Location - address fields
  expect(page).to have_content("Set Location", wait: 5)
  fill_in_fieldset "Street address", with: "123 Main Street"
  fill_in_fieldset "City", with: "Millbrook"
  fill_in_fieldset "Postcode", with: "ZZMB 1RS"

  click_button "Continue"

  # Step 3: Tags & Categories
  expect(page).to have_content("Tags & Categories", wait: 5)
  click_button "Continue"

  # Step 4: Contact Information
  expect(page).to have_content("Contact Information", wait: 5)
  click_button "Continue"

  # Step 5: Invite a Partner Admin (optional)
  expect(page).to have_content("Invite a Partner Admin", wait: 5)
  click_button "Continue"

  # Step 6: Confirm & Create
  expect(page).to have_content("Partner will be created", wait: 5)
  click_button "Create Partner"
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

# Partner page paginator steps

Given("the partner has {int} upcoming events") do |count|
  count.times do |i|
    date = Time.current + (i % 28).days + 1.day
    create(:event, partner: @partner, dtstart: date, dtend: date + 2.hours)
  end
end

When("I visit the partner page for {string}") do |name|
  create_default_site
  partner = Partner.find_by(name: name)
  visit "/partners/#{partner.slug}"
end

Then("I should see a paginator") do
  expect(page).to have_css(".paginator")
end

Then("I should still be on the partner page for {string}") do |name|
  partner = Partner.find_by(name: name)
  expect(current_path).to include("/partners/#{partner.slug}")
end
