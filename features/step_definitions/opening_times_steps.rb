# frozen_string_literal: true

# Step definitions for opening times picker (Stimulus controller)

When("I add opening time {string} from {string} to {string}") do |day, open_time, close_time|
  # Select the day
  select day, from: "day"

  # Set opening time
  fill_in "open", with: open_time

  # Set closing time
  fill_in "close", with: close_time

  # Click Add button
  click_button "Add"

  # Wait for the opening time to be added to the list
  expect(page).to have_css("[data-opening-times-target='list'] li", wait: 5)
end

When("I add all-day opening time for {string}") do |day|
  # Select the day
  select day, from: "day"

  # Check all day checkbox
  check "allDay"

  # Click Add button
  click_button "Add"

  # Wait for the opening time to be added to the list
  expect(page).to have_css("[data-opening-times-target='list'] li", wait: 5)
end

Then("the partner should have opening time on {string}") do |day|
  expect(page).to have_css("[data-opening-times-target='list']", text: day)
end
