# frozen_string_literal: true

# Step definitions for navigation

When("I visit the home page") do
  create_default_site
  visit "/"
end

When("I visit the admin dashboard") do
  port = Capybara.current_session.server.port
  visit "http://admin.lvh.me:#{port}/"
end

When("I click {string}") do |link_text|
  click_link link_text
end

When("I click the {string} button") do |button_text|
  click_button button_text
end

When("I navigate to {string}") do |path|
  visit path
end

When("I go to the {string} admin section") do |section|
  click_link section
  await_datatables
end

Then("I should be on the {string} page") do |page_name|
  expect(page).to have_content(page_name)
end

Then("I should see {string}") do |content|
  expect(page).to have_content(content)
end

Then("I should not see {string}") do |content|
  expect(page).not_to have_content(content)
end

Then("I should see a success message") do
  expect(page).to have_selector(".alert-success")
end

Then("I should see the success message {string}") do |message|
  expect(page).to have_selector(".alert-success", text: message)
end

Then("I should see an error message") do
  expect(page).to have_selector(".alert-danger")
end

Then("I should see the error message {string}") do |message|
  expect(page).to have_selector(".alert-danger", text: message)
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I wait for the datatable to load") do
  await_datatables
end
