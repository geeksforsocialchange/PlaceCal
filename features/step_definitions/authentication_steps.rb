# frozen_string_literal: true

# Step definitions for authentication

Given('I am a root user') do
  @current_user = create(:root_user, email: 'admin@normalcal.org', password: 'password')
end

Given('I am a partner admin for {string}') do |partner_name|
  partner = Partner.find_by(name: partner_name) || create(:partner, name: partner_name)
  @current_user = create(:partner_admin, partner: partner, password: 'password')
end

Given('I am a neighbourhood admin for {string}') do |neighbourhood_name|
  neighbourhood = Neighbourhood.find_by(name: neighbourhood_name) || create(:neighbourhood, name: neighbourhood_name)
  @current_user = create(:neighbourhood_admin, neighbourhood: neighbourhood, password: 'password')
end

Given('I am logged in') do
  create_default_site
  visit '/users/sign_in'
  fill_in 'Email', with: @current_user.email
  fill_in 'Password', with: 'password'
  click_button 'Log in'
  expect(page).to have_content('Signed in successfully')
end

Given('I am logged in as a root user') do
  step 'I am a root user'
  step 'I am logged in'
end

When('I log out') do
  click_button 'Sign out'
end

Then('I should be logged in') do
  expect(page).to have_button('Sign out')
end

Then('I should be logged out') do
  expect(page).to have_link('Sign in')
end
