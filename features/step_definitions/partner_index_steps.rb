# frozen_string_literal: true

# Step definitions for partner index table functionality

# Setup steps
Given("there is a partner called {string} with a calendar") do |name|
  partner = create(:partner, name: name)
  create(:calendar, partner: partner, name: "#{name} Calendar")
end

Given("the partner {string} has the partnership {string}") do |partner_name, partnership_name|
  partner = Partner.find_by(name: partner_name) || create(:partner, name: partner_name)
  partnership = Partnership.find_by(name: partnership_name) ||
                create(:partnership, name: partnership_name)
  partner.tags << partnership unless partner.tags.include?(partnership)
end

Given("the partner {string} has the category {string}") do |partner_name, category_name|
  partner = Partner.find_by(name: partner_name) || create(:partner, name: partner_name)
  category = Category.find_by(name: category_name) ||
             create(:category, name: category_name)
  partner.tags << category unless partner.tags.include?(category)
end

Given("the partner {string} has a calendar") do |partner_name|
  partner = Partner.find_by(name: partner_name)
  create(:calendar, partner: partner, name: "#{partner_name} Calendar")
end

Given("the partner {string} has an admin user") do |partner_name|
  partner = Partner.find_by(name: partner_name)
  user = create(:user, email: "admin-#{partner_name.parameterize}@example.com")
  partner.users << user unless partner.users.include?(user)
end

# Table verification steps
Then("I should see the partner table with columns:") do |table|
  await_datatables
  columns = table.raw.flatten
  columns.each do |column|
    # Headers are uppercase in the table
    expect(page).to have_selector("th", text: /#{column}/i)
  end
end

Then("I should see {string} in the partner table") do |content|
  await_datatables
  within('[data-controller="admin-table"]') do
    expect(page).to have_content(content)
  end
end

Then("I should not see {string} in the partner table") do |content|
  await_datatables
  within('[data-controller="admin-table"]') do
    expect(page).not_to have_content(content)
  end
end

Then("I should see a calendar connected indicator for {string}") do |partner_name|
  await_datatables
  # Look for the green check icon in the calendars column for this partner's row
  partner_row = find("tr", text: partner_name)
  within(partner_row) do
    expect(page).to have_selector(".text-emerald-600 svg", visible: :all)
  end
end

Then("I should see an admin indicator for {string}") do |partner_name|
  await_datatables
  partner_row = find("tr", text: partner_name)
  within(partner_row) do
    # Should have a green check for admins
    expect(page).to have_selector(".text-emerald-600", count: 1..10)
  end
end

# Filter steps
When("I filter by {string} with value {string}") do |filter_label, value|
  await_datatables

  # Find the select dropdown that contains the filter label as an option placeholder
  select_element = find('select[data-admin-table-target="filter"]', text: filter_label)
  select_element.select(value)

  # Wait for the table to reload
  sleep 0.5
  await_datatables
end

Then("the {string} filter should show {string}") do |filter_label, expected_value|
  # Find the filter dropdown and check its selected option
  selects = all('select[data-admin-table-target="filter"]')
  matching_select = selects.find { |s| s.has_selector?("option", text: filter_label, visible: :all) }

  expect(matching_select).not_to be_nil, "Could not find filter dropdown for '#{filter_label}'"
  expect(matching_select.value).not_to be_empty

  # The value in the select is the ID, but we want to verify the visible text
  selected_option = matching_select.find("option[value='#{matching_select.value}']")
  expect(selected_option.text).to eq(expected_value)
end

# Click to filter steps
When("I click the ward {string} in the partner table") do |ward_name|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    click_button ward_name
  end
  sleep 0.5
  await_datatables
end

When("I click the partnership {string} in the partner table") do |partnership_name|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    click_button partnership_name
  end
  sleep 0.5
  await_datatables
end

# Search step
When("I search for {string} in the partner table") do |search_term|
  await_datatables
  fill_in "Search by name...", with: search_term
  sleep 0.5 # Debounce delay
  await_datatables
end

# Helper to wait for datatables to load
def await_datatables
  # Wait for loading indicator to disappear
  expect(page).not_to have_content("Loading data...", wait: 10)
  # Wait for table rows to appear (either data rows or "No records found")
  expect(page).to have_selector('[data-controller="admin-table"] tbody tr', wait: 10)
end
