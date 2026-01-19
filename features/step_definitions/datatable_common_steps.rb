# frozen_string_literal: true

# Shared step definitions for admin datatable functionality
# These steps work with any admin table using the admin-table Stimulus controller

# ===========================================
# Table Content Verification
# ===========================================

Then("I should see the admin table with columns:") do |table|
  await_datatables
  columns = table.raw.flatten
  columns.each do |column|
    expect(page).to have_selector("th", text: /#{Regexp.escape(column)}/i)
  end
end

Then("I should see {string} in the admin table") do |content|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    expect(page).to have_content(content)
  end
end

Then("I should not see {string} in the admin table") do |content|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    expect(page).not_to have_content(content)
  end
end

Then("the admin table should have {int} row(s)") do |count|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    expect(page).to have_selector("tr", count: count)
  end
end

Then("the admin table should be empty") do
  await_datatables
  within('[data-controller="admin-table"]') do
    expect(page).to have_content("No entries found")
  end
end

# ===========================================
# Filter Steps
# ===========================================

When("I filter by {string} with value {string}") do |filter_label, value|
  await_datatables

  # Find the select dropdown that contains the filter label as an option placeholder
  select_element = find('select[data-admin-table-target="filter"]', text: filter_label)
  select_element.select(value)

  # Wait for the table to reload
  sleep 0.3
  await_datatables
end

When("I click {string} in the {string} radio filter") do |button_text, filter_label|
  await_datatables

  # Find the radio filter fieldset by its label text
  fieldset = find('fieldset[data-admin-table-target="radioFilter"]', text: filter_label)
  within(fieldset) do
    click_button button_text
  end

  # Wait for the table to reload
  sleep 0.3
  await_datatables
end

When("I filter the {string} dropdown to {string}") do |filter_label, value|
  await_datatables

  # Find select by its label/placeholder option text
  selects = all('select[data-admin-table-target="filter"]')
  matching_select = selects.find { |s| s.has_selector?("option", text: filter_label, visible: :all) }

  expect(matching_select).not_to be_nil, "Could not find filter dropdown for '#{filter_label}'"
  matching_select.select(value)

  sleep 0.3
  await_datatables
end

Then("the {string} filter should show {string}") do |filter_label, expected_value|
  # Find the filter dropdown and check its selected option
  selects = all('select[data-admin-table-target="filter"]')
  matching_select = selects.find { |s| s.has_selector?("option", text: filter_label, visible: :all) }

  expect(matching_select).not_to be_nil, "Could not find filter dropdown for '#{filter_label}'"
  expect(matching_select.value).not_to be_empty

  # The value in the select is the ID, but we want to verify the visible text
  # Use start_with to allow for count suffix like "Age Friendly (1)"
  selected_option = matching_select.find("option[value='#{matching_select.value}']")
  expect(selected_option.text).to start_with(expected_value)
end

Then("the {string} filter should be cleared") do |filter_label|
  selects = all('select[data-admin-table-target="filter"]')
  matching_select = selects.find { |s| s.has_selector?("option", text: filter_label, visible: :all) }

  expect(matching_select).not_to be_nil, "Could not find filter dropdown for '#{filter_label}'"
  expect(matching_select.value).to be_empty
end

# ===========================================
# Clear Filters
# ===========================================

# NOTE: "I click {string}" step is defined in navigation_steps.rb

When("I clear all filters") do
  click_link "Clear filters"
  await_datatables
end

# ===========================================
# Click-to-Filter Steps
# ===========================================

When("I click the clickable cell {string} in the admin table") do |cell_text|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    click_button cell_text
  end
  sleep 0.3
  await_datatables
end

When("I click {string} in the table to filter") do |cell_text|
  await_datatables
  within('[data-controller="admin-table"] tbody') do
    click_button cell_text
  end
  sleep 0.3
  await_datatables
end

# ===========================================
# Search Steps
# ===========================================

When("I search for {string} in the admin table") do |search_term|
  await_datatables
  # Find the search input - it may have different placeholder text
  search_input = find('input[data-admin-table-target="search"]')
  search_input.fill_in(with: search_term)
  sleep 0.3 # Debounce delay
  await_datatables
end

When("I search the table for {string}") do |search_term|
  await_datatables
  search_input = find('input[data-admin-table-target="search"]')
  search_input.fill_in(with: search_term)
  sleep 0.3
  await_datatables
end

When("I clear the search") do
  search_input = find('input[data-admin-table-target="search"]')
  search_input.fill_in(with: "")
  sleep 0.3
  await_datatables
end

# ===========================================
# Status Indicator Steps
# ===========================================

Then("I should see a green check indicator for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    expect(page).to have_selector(".text-emerald-600 svg", visible: :all)
  end
end

Then("I should see a red cross indicator for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    expect(page).to have_selector(".text-red-500 svg", visible: :all)
  end
end

Then("I should see an orange warning indicator for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    expect(page).to have_selector(".text-orange-500 svg", visible: :all)
  end
end

# ===========================================
# Badge Steps
# ===========================================

Then("I should see a {string} badge for {string}") do |badge_type, row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)

  # Map badge types to Tailwind color classes
  badge_colors = {
    "green" => "bg-green",
    "emerald" => "bg-emerald",
    "blue" => "bg-blue",
    "purple" => "bg-purple",
    "teal" => "bg-teal",
    "orange" => "bg-orange",
    "red" => "bg-red",
    "gray" => "bg-gray"
  }

  color_class = badge_colors[badge_type.downcase]
  raise "Unknown badge type: #{badge_type}" unless color_class

  within(row) do
    expect(page).to have_selector("[class*='#{color_class}']")
  end
end

Then("I should see a badge with text {string} for {string}") do |badge_text, row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    expect(page).to have_selector("span", text: badge_text)
  end
end

# ===========================================
# Row Navigation Steps
# ===========================================

When("I click on the row for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    # Click the first link in the row (usually the name/title)
    first("a").click
  end
end

When("I click the edit button for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    click_link "Edit"
  end
end

When("I click the view button for {string}") do |row_identifier|
  await_datatables
  row = find("tr", text: row_identifier)
  within(row) do
    click_link "View"
  end
end

# ===========================================
# Pagination Steps
# ===========================================

Then("I should see pagination controls") do
  await_datatables
  expect(page).to have_selector('[data-admin-table-target="pagination"]')
end

Then("I should see {string} in the table info") do |info_text|
  await_datatables
  within('[data-admin-table-target="info"]') do
    expect(page).to have_content(info_text)
  end
end

When("I go to page {int}") do |page_number|
  await_datatables
  within('[data-admin-table-target="pagination"]') do
    click_link page_number.to_s
  end
  await_datatables
end

When("I click next page") do
  await_datatables
  within('[data-admin-table-target="pagination"]') do
    click_link "Next"
  end
  await_datatables
end

When("I click previous page") do
  await_datatables
  within('[data-admin-table-target="pagination"]') do
    click_link "Previous"
  end
  await_datatables
end

# ===========================================
# Sorting Steps
# ===========================================

When("I click the {string} column header to sort") do |column_name|
  await_datatables
  header = find("th", text: column_name)
  header.click
  await_datatables
end

Then("the table should be sorted by {string}") do |column_name|
  await_datatables
  # The sorted column has a sort indicator
  header = find("th", text: column_name)
  expect(header).to have_selector("svg", visible: :all)
end
