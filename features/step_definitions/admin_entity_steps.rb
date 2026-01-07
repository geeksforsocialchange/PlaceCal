# frozen_string_literal: true

# Step definitions for admin entities (neighbourhoods, collections, supporters, dashboard)

# Neighbourhood steps
Given("there is a neighbourhood called {string}") do |name|
  create(:neighbourhood, name: name)
end

# Collection steps
Given("there is a collection called {string}") do |name|
  create(:collection, name: name)
end

# Supporter steps
Given("there is a supporter called {string}") do |name|
  create(:supporter, name: name)
end

# Dashboard steps
Given("there are {int} partners in the system") do |count|
  create_list(:partner, count)
end

Given("there are {int} calendars in the system") do |count|
  partner = Partner.first || create(:partner)
  count.times do
    create(:calendar, partner: partner)
  end
end

Then("I should see partner count information") do
  # Dashboard shows partner statistics
  expect(page).to have_content("Partner")
end

Then("I should see calendar count information") do
  # Dashboard shows calendar statistics
  expect(page).to have_content("Calendar")
end
