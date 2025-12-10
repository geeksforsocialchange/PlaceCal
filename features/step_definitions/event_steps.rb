# frozen_string_literal: true

# Step definitions for events

Given('there is an event called {string}') do |name|
  partner = @partner || create(:partner)
  @event = create(:event, name: name, partner: partner)
end

Given('there is an event called {string} on {string}') do |name, date_str|
  partner = @partner || create(:partner)
  date = Date.parse(date_str)
  @event = create(:event, name: name, partner: partner, dtstart: date.to_datetime)
end

Given('the following events exist:') do |table|
  partner = @partner || create(:partner)
  table.hashes.each do |row|
    date = row['date'] ? Date.parse(row['date']).to_datetime : Time.current
    create(:event, name: row['name'], partner: partner, dtstart: date)
  end
end

When('I view the events page') do
  create_default_site
  visit '/events'
end

When('I view the event {string}') do |name|
  event = Event.find_by(name: name)
  visit "/events/#{event.id}"
end

Then('I should see the event {string}') do |name|
  expect(page).to have_content(name)
end

Then('I should see {int} events') do |count|
  expect(page).to have_selector('.event', count: count)
end
