# frozen_string_literal: true

# Step definitions for calendar management

Given("there is a calendar called {string} for partner {string}") do |calendar_name, partner_name|
  partner = Partner.find_by(name: partner_name) || create(:partner, name: partner_name)
  @calendar = create(:calendar, name: calendar_name, partner: partner)
end

Given("the calendar {string} has URL {string}") do |name, url|
  calendar = Calendar.find_by(name: name)
  calendar.update!(source: url)
end

When("I create a new calendar with name {string} for {string}") do |name, partner_name|
  partner = Partner.find_by(name: partner_name)
  click_link "Calendars"
  await_datatables
  click_link "Add New Calendar"
  fill_in "Name", with: name
  # Select partner would need Select2 interaction
  click_button "Create Calendar"
end

When("I view the calendar {string}") do |name|
  click_link "Calendars"
  await_datatables
  click_link name
end

Then("I should see the calendar {string} in the list") do |name|
  click_link "Calendars"
  await_datatables
  expect(page).to have_content(name)
end

Then("the calendar should show as {string}") do |state|
  expect(page).to have_content(state)
end

When("I edit the calendar {string}") do |name|
  click_link "Calendars"
  await_datatables
  # The calendar name is a link to the edit page
  click_link name
end
