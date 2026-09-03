# frozen_string_literal: true

# Step definitions for site content pages (#3368, WP 1.1)

Given("I am a site admin for {string}") do |site_name|
  site = Site.find_by(name: site_name) ||
         create(:site, name: site_name, slug: site_name.parameterize)
  @current_user = create(:user, password: "password", password_confirmation: "password")
  site.update!(site_admin: @current_user)
  @site = site
end

Given("the site {string} has a page called {string}") do |site_name, title|
  site = Site.find_by(name: site_name)
  create(:page, site: site, title: title, slug: title.parameterize)
end

Then("the site {string} should have a page at {string}") do |site_name, slug|
  site = Site.find_by(name: site_name)
  expect(site.pages.find_by(slug: slug)).to be_present
end

# Visits the new page form on the current (admin) host directly. The
# "Add Page" click is Turbo-driven and occasionally fails to navigate under
# full-suite load; the reserved slug scenario is about validation, not the
# click, so it goes straight to the form.
When("I open the new page form") do
  uri = URI(page.current_url)
  visit "#{uri.scheme}://#{uri.host}:#{uri.port}/pages/new"
  expect(page).to have_content("New Page")
end
