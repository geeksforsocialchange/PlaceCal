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
    click_link text, match: :first
  elsif page.has_button?(text, wait: 1)
    click_button text, match: :first
  else
    # Fall back to finding any clickable element with this text
    find(:xpath, "//*[text()='#{text}' or contains(text(), '#{text}')]", match: :first).click
  end
end

When("I click {string} and confirm") do |text|
  accept_confirm do
    # Try link first, then button, then any clickable element
    if page.has_link?(text, wait: 1)
      click_link text
    elsif page.has_button?(text, wait: 1)
      click_button text
    else
      find(:xpath, "//*[text()='#{text}' or contains(text(), '#{text}')]", match: :first).click
    end
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
  # Try standard fill_in first (works with label, name, or id)

  fill_in field, with: value
rescue Capybara::ElementNotFound
  # Fall back to finding by fieldset legend (daisyUI pattern)
  # First try matching the legend text directly for better accuracy
  fieldsets = page.all("fieldset").select do |fs|
    legend = fs.first("legend")
    next false unless legend

    # Match against legend text - exact or starts with (to handle "Partner Name *" for "Name")
    legend_text = legend.text.strip
    legend_text == field ||
      legend_text.start_with?(field) ||
      legend_text.downcase.include?(field.downcase)
  end

  # If multiple fieldsets match, prefer exact match
  fieldset = fieldsets.find { |fs| fs.first("legend")&.text&.strip == field }
  fieldset ||= fieldsets.first

  raise Capybara::ElementNotFound, "Could not find fieldset for '#{field}'" unless fieldset

  input = fieldset.find("input, textarea, select", match: :first)
  input.set(value)
end

When("I wait for the datatable to load") do
  await_datatables
end

When("I check {string}") do |checkbox_label|
  check checkbox_label
rescue Capybara::ElementNotFound
  # Fall back to finding checkbox by nearby text (daisyUI pattern)
  begin
    label = page.find("label", text: checkbox_label)
    checkbox = label.find("input[type='checkbox']")
    checkbox.check
  rescue Capybara::ElementNotFound
    # Try finding checkbox by id derived from label
    field_id = checkbox_label.downcase.gsub(/\s+/, "_")
    page.find("input[type='checkbox'][id*='#{field_id}']").check
  end
end

When("I uncheck {string}") do |checkbox_label|
  uncheck checkbox_label
end

# Navigate to a specific tab in the partner form (daisyUI tabs)
When("I go to the {string} step") do |step_name|
  # Map step names to their tab aria-labels (with emoji icons)
  tab_labels = {
    "basic info" => "📋 Basic Info",
    "place" => "📍 Location",
    "location" => "📍 Location",
    "contact" => "📞 Contact",
    "tags" => "🏷️ Tags",
    "admin" => "👥 Admins",
    "admins" => "👥 Admins",
    "settings" => "⚙ Settings",
    "calendars" => "📅 Calendars"
  }

  tab_label = tab_labels[step_name.downcase]
  raise "Unknown step: #{step_name}" unless tab_label

  # Find and click the tab by aria-label attribute
  tab = page.find("input.tab[aria-label='#{tab_label}']", wait: 10)
  tab.click

  # Wait for the tab content to be visible
  sleep 0.2
end

When("I click the {string} tab") do |tab_name|
  # Find tab by partial aria-label match (handles emoji prefixes)
  tab = page.find("input.tab[aria-label*='#{tab_name}']", wait: 10)
  tab.click
  sleep 0.2
end

When("I go to form step {int}") do |step_number|
  # Map step numbers to tab labels (1-based for user)
  tab_labels = ["Basic Info", "Location", "Contact", "Tags", "Admins"]
  tab_label = tab_labels[step_number - 1]
  raise "Invalid step number: #{step_number}" unless tab_label

  tab = page.find("input.tab[aria-label='#{tab_label}']", wait: 10)
  tab.click
  sleep 0.2
end
