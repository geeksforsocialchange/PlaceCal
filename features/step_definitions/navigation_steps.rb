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

# Navigate to a specific tab in the form (daisyUI tabs)
# Supports partner, calendar, and user forms
When("I go to the {string} step") do |step_name|
  # Map step names to their tab data-hash attributes
  # Partner form: basic, location, contact, tags, calendars, admins, preview, settings
  # Calendar form: source, location, contact, preview, admin
  # User form: personal, permissions, admin
  tab_hashes = {
    # Partner form tabs
    "basic info" => "basic",
    "place" => "location",
    "tags" => "tags",
    "admins" => "admins",
    "settings" => "settings",
    "calendars" => "calendars",
    # Calendar form tabs
    "source" => "source",
    # User form tabs
    "personal" => "personal",
    "personal details" => "personal",
    "permissions" => "permissions",
    # Shared tab names
    "location" => "location",
    "contact" => "contact",
    "admin" => "admin",
    "preview" => "preview"
  }

  tab_hash = tab_hashes[step_name.downcase]
  raise "Unknown step: #{step_name}" unless tab_hash

  # Find and click the tab by data-hash attribute (more reliable than emoji aria-labels)
  tab = page.find("input.tab[data-hash='#{tab_hash}']", wait: 10)

  # Handle unsaved changes confirmation if it appears
  begin
    accept_confirm { tab.click }
  rescue Capybara::ModalNotFound
    # No confirmation appeared, which is fine
  end

  # Wait for the tab content to be visible
  sleep 0.2
end

When("I click the {string} tab") do |tab_name|
  # Map common tab names to data-hash values
  # Partner form: basic, location, contact, tags, calendars, admins, preview, settings
  # Calendar form: source, location, contact, preview, admin
  # User form: personal, permissions, admin
  tab_hashes = {
    # Partner form tabs
    "Basic Info" => "basic",
    "Tags" => "tags",
    "Admins" => "admins",
    "Settings" => "settings",
    "Calendars" => "calendars",
    # Calendar form tabs
    "Source" => "source",
    # User form tabs
    "Personal" => "personal",
    "Personal Details" => "personal",
    "Permissions" => "permissions",
    # Shared tabs
    "Location" => "location",
    "Contact" => "contact",
    "Admin" => "admin",
    "Preview" => "preview"
  }

  # Try data-hash first, fall back to aria-label match
  tab_hash = tab_hashes[tab_name]
  tab = if tab_hash
          page.find("input.tab[data-hash='#{tab_hash}']", wait: 10)
        else
          page.find("input.tab[aria-label*='#{tab_name}']", wait: 10)
        end

  # Handle unsaved changes confirmation if it appears
  begin
    accept_confirm { tab.click }
  rescue Capybara::ModalNotFound
    # No confirmation appeared, which is fine
  end
  sleep 0.2
end

When("I go to form step {int}") do |step_number|
  # Map step numbers to data-hash values (1-based for user)
  # Partner form uses: basic, location, contact, tags, admins
  tab_hashes = %w[basic location contact tags admins]
  tab_hash = tab_hashes[step_number - 1]
  raise "Invalid step number: #{step_number}" unless tab_hash

  tab = page.find("input.tab[data-hash='#{tab_hash}']", wait: 10)
  # Handle unsaved changes confirmation if it appears
  begin
    accept_confirm { tab.click }
  rescue Capybara::ModalNotFound
    # No confirmation appeared
  end
  sleep 0.2
end
