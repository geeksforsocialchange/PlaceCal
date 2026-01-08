# frozen_string_literal: true

# Step definitions for user management

Given("there is a user called {string}") do |name|
  parts = name.split(" ", 2)
  first_name = parts[0]
  last_name = parts[1] || "User"
  email = "#{first_name.downcase}.#{last_name.downcase.gsub(' ', '')}@example.org"

  @user = create(:user,
                 first_name: first_name,
                 last_name: last_name,
                 email: email)
end

When("I edit the user {string}") do |name|
  click_link "Users"
  await_datatables
  # The user name is a link to the edit page (first name links to edit)
  # Find within the datatable to avoid ambiguity with column headers
  parts = name.split(" ", 2)
  first_name = parts[0]
  within("[data-admin-table-target='tbody']") do
    click_link first_name
  end
end

When("I create a new user with name {string}") do |name|
  parts = name.split(" ", 2)
  first_name = parts[0]
  last_name = parts[1] || "User"
  email = "#{first_name.downcase}.#{last_name.downcase}@example.org"

  click_link "Users"
  await_datatables
  click_link "Add User"
  fill_in "First name", with: first_name
  fill_in "Last name", with: last_name
  fill_in "Email", with: email
  click_button "Create User"
end

Then("I should see the user {string} in the list") do |name|
  click_link "Users"
  await_datatables
  expect(page).to have_content(name)
end
