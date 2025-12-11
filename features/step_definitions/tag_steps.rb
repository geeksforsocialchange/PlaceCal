# frozen_string_literal: true

# Step definitions for tag management

Given('there is a tag called {string}') do |name|
  @tag = create(:category, name: name)
end

Given('there is a category tag called {string}') do |name|
  @tag = create(:category, name: name)
end

Given('there is a facility tag called {string}') do |name|
  @tag = create(:facility, name: name)
end

Given('there is a partnership tag called {string}') do |name|
  @tag = create(:partnership, name: name)
end

When('I view the tag {string}') do |name|
  click_link 'Tags'
  await_datatables
  click_link name
end

Then('I should see the tag {string}') do |name|
  expect(page).to have_content(name)
end

Then('the partner {string} should have tag {string}') do |partner_name, tag_name|
  partner = Partner.find_by(name: partner_name)
  tag = Tag.find_by(name: tag_name)
  expect(partner.tags).to include(tag)
end
