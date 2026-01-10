# frozen_string_literal: true

# Step definitions for partner index table functionality
# Note: Generic datatable steps are in datatable_common_steps.rb

# ===========================================
# Partner-specific Setup Steps
# ===========================================

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

# ===========================================
# Partner-specific Table Verification
# (These wrap the generic steps for backward compatibility)
# ===========================================

Then("I should see the partner table with columns:") do |table|
  step "I should see the admin table with columns:", table
end

Then("I should see {string} in the partner table") do |content|
  step "I should see \"#{content}\" in the admin table"
end

Then("I should not see {string} in the partner table") do |content|
  step "I should not see \"#{content}\" in the admin table"
end

Then("I should see a calendar connected indicator for {string}") do |partner_name|
  step "I should see a green check indicator for \"#{partner_name}\""
end

Then("I should see an admin indicator for {string}") do |partner_name|
  step "I should see a green check indicator for \"#{partner_name}\""
end

# ===========================================
# Partner-specific Click-to-Filter Steps
# ===========================================

When("I click the ward {string} in the partner table") do |ward_name|
  step "I click the clickable cell \"#{ward_name}\" in the admin table"
end

When("I click the partnership {string} in the partner table") do |partnership_name|
  step "I click the clickable cell \"#{partnership_name}\" in the admin table"
end

# ===========================================
# Partner-specific Search Step
# ===========================================

When("I search for {string} in the partner table") do |search_term|
  step "I search for \"#{search_term}\" in the admin table"
end
