# frozen_string_literal: true

# Step definitions for events

Given("there is an event called {string}") do |name|
  partner = @partner || create(:partner)
  @event = create(:event, summary: name, partner: partner)
end

Given("there is an event called {string} on {string}") do |name, date_str|
  partner = @partner || create(:partner)
  date = Date.parse(date_str)
  @event = create(:event, summary: name, partner: partner, dtstart: date.to_datetime)
end

Given("the following events exist:") do |table|
  partner = @partner || create(:partner)
  table.hashes.each do |row|
    date = row["date"] ? Date.parse(row["date"]).to_datetime : Time.current
    create(:event, summary: row["name"], partner: partner, dtstart: date)
  end
end

When("I view the events page") do
  create_default_site
  visit "/events"
end

When("I view the event {string}") do |name|
  event = Event.find_by(summary: name)
  visit "/events/#{event.id}"
end

Then("I should see the event {string}") do |name|
  expect(page).to have_content(name)
end

Then("I should see {int} events") do |count|
  expect(page).to have_selector(".event", count: count)
end

# Paginator steps

Given("there are {int} events in the next month") do |count|
  partner = @partner || create(:partner)
  count.times do |i|
    date = Time.current + (i % 28).days + 1.day
    create(:event, partner: partner, dtstart: date, dtend: date + 2.hours)
  end
end

Then("I should see {string} in the paginator") do |text|
  within(".paginator") do
    expect(page).to have_content(text)
  end
end

When("I click the forward arrow") do
  find(".paginator__arrow--forwards a").click
end

Then("I should see a {string} button") do |text|
  expect(page).to have_link(text)
end

Then("I should see {string} as active in the paginator") do |text|
  within(".paginator__buttons li.active") do
    expect(page).to have_content(text)
  end
end

Then("I should not see {string} as active in the paginator") do |text|
  within(".paginator__buttons li.active") do
    expect(page).not_to have_content(text)
  end
end

When("I select the date {string}") do |date_str|
  within(".breadcrumb__date-picker-dropdown") do
    fill_in "date", with: date_str
  end
end
