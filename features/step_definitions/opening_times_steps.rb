# frozen_string_literal: true

# Step definitions for opening times picker (Stimulus controller)

When("I add opening time {string} from {string} to {string}") do |day, open_time, close_time|
  # Wait for Stimulus controller to be connected
  expect(page).to have_css("[data-controller='opening-times']", wait: 5)

  # Select the day using the Stimulus target
  find("[data-opening-times-target='day']").select(day)

  # Set opening time using the Stimulus target
  find("[data-opening-times-target='open']").set(open_time)

  # Set closing time using the Stimulus target
  find("[data-opening-times-target='close']").set(close_time)

  # Click Add button using the Stimulus action
  find("button[data-action*='opening-times#addOpeningTime']").click

  # Wait for the opening time to be added to the list (the list item is a div with flex class)
  expect(page).to have_css("[data-opening-times-target='list'] div.flex", text: day, wait: 5)
end

When("I add all-day opening time for {string}") do |day|
  # Wait for Stimulus controller to be connected
  expect(page).to have_css("[data-controller='opening-times']", wait: 5)

  # Select the day using the Stimulus target
  find("[data-opening-times-target='day']").select(day)

  # Check all day checkbox using the Stimulus target
  find("[data-opening-times-target='allDay']").check

  # Click Add button using the Stimulus action
  find("button[data-action*='opening-times#addOpeningTime']").click

  # Wait for the opening time to be added to the list (the list item is a div with flex class)
  expect(page).to have_css("[data-opening-times-target='list'] div.flex", text: day, wait: 5)
end

Then("the partner should have opening time on {string}") do |day|
  expect(page).to have_css("[data-opening-times-target='list']", text: day)
end
