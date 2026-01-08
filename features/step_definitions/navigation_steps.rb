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

When("I click {string}") do |text|
  # Try clicking as a link first, then as a button
  if page.has_link?(text, wait: 1)
    click_link text
  elsif page.has_button?(text, wait: 1)
    click_button text
  else
    # Fall back to finding any clickable element with this text
    find(:xpath, "//*[text()='#{text}' or contains(text(), '#{text}')]").click
  end
end

When("I click {string} and confirm") do |link_text|
  accept_confirm do
    click_link link_text
  end
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
  # Look for green alert (Tailwind) or Bootstrap alert-success
  expect(page).to have_selector("[role='alert'].bg-green-50, .alert-success")
end

Then("I should see the success message {string}") do |message|
  expect(page).to have_selector("[role='alert'].bg-green-50, .alert-success", text: message)
end

Then("I should see an error message") do
  # Look for red alert (Tailwind) or Bootstrap alert-danger
  expect(page).to have_selector("[role='alert'].bg-red-50, .alert-danger")
end

Then("I should see the error message {string}") do |message|
  expect(page).to have_selector("[role='alert'].bg-red-50, .alert-danger", text: message)
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I wait for the datatable to load") do
  await_datatables
end

When("I check {string}") do |checkbox_label|
  check checkbox_label
end

When("I uncheck {string}") do |checkbox_label|
  uncheck checkbox_label
end

# Navigate to a specific step in a multi-step form
When("I go to the {string} step") do |step_name|
  # Map step names to their indices
  step_indices = {
    "basic info" => 0,
    "place" => 1,
    "contact" => 2,
    "tags" => 3,
    "admin" => 4
  }

  step_index = step_indices[step_name.downcase]
  raise "Unknown step: #{step_name}" unless step_index

  # Find and click the step button by data-step attribute
  step_button = page.find("button[data-step='#{step_index}']")
  step_button.click

  # Wait a moment for Stimulus to process the click and update the DOM
  sleep 0.5

  # Use JavaScript to ensure the step is shown (fallback if Stimulus didn't work)
  page.execute_script(<<~JS)
    const steps = document.querySelectorAll('[data-multi-step-form-target="step"]');
    steps.forEach((step, index) => {
      if (index === #{step_index}) {
        step.classList.remove('hidden');
      } else {
        step.classList.add('hidden');
      }
    });
  JS

  # Wait for the DOM to update
  sleep 0.1
end

When("I go to form step {int}") do |step_number|
  # Click the step button by step index (0-based internally, 1-based for user)
  step_index = step_number - 1
  step_button = page.find("button[data-step='#{step_index}']")
  step_button.click
  page.find("[data-multi-step-form-target='step']:not(.hidden)", wait: 2)
end
