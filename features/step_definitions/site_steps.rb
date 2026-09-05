# frozen_string_literal: true

# Step definitions for site management

Given("there is a site called {string}") do |name|
  slug = name.parameterize
  @site = create(:site, name: name, slug: slug)
end

Given("there is a published site called {string}") do |name|
  slug = name.parameterize
  ward = create(:riverside_ward)
  @site = create(:site, name: name, slug: slug, is_published: true)
  @site.neighbourhoods << ward
end

Given("there is a partner called {string} in the site {string}") do |partner_name, site_name|
  site = Site.find_by(name: site_name) || create(:site, name: site_name, slug: site_name.parameterize, is_published: true)
  ward = create(:riverside_ward)
  address = create(:address, neighbourhood: ward)
  @partner = create(:partner, name: partner_name, address: address)

  # Add ward to site to link partner
  site.neighbourhoods << ward unless site.neighbourhoods.include?(ward)
end

Given("there is an event called {string} for partner {string}") do |event_name, partner_name|
  partner = Partner.find_by(name: partner_name) || create(:partner, name: partner_name)
  @event = create(:event, summary: event_name, organiser: partner, dtstart: Time.zone.local(2022, 11, 10))
end

When("I visit the site {string}") do |name|
  site = Site.find_by(name: name)
  port = Capybara.current_session.server.port
  visit "http://#{site.slug}.lvh.me:#{port}/"
end

When("I visit the events page for site {string}") do |name|
  site = Site.find_by(name: name)
  port = Capybara.current_session.server.port
  visit "http://#{site.slug}.lvh.me:#{port}/events"
end

When("I visit the partners page for site {string}") do |name|
  site = Site.find_by(name: name)
  port = Capybara.current_session.server.port
  visit "http://#{site.slug}.lvh.me:#{port}/partners"
end

When("I visit the partner {string} on site {string}") do |partner_name, site_name|
  site = Site.find_by(name: site_name)
  partner = Partner.find_by(name: partner_name)
  port = Capybara.current_session.server.port
  visit "http://#{site.slug}.lvh.me:#{port}/partners/#{partner.id}"
end

When("I visit the news page for {string}") do |site_name|
  site = Site.find_by(name: site_name)
  port = Capybara.current_session.server.port
  visit "http://#{site.slug}.lvh.me:#{port}/news"
end

# Region filter: a "region" is a Partnership tag on the site (#3368 D7)

Given("the site {string} has the partnership {string}") do |site_name, partnership_name|
  site = Site.find_by(name: site_name)
  partnership = Partnership.find_by(name: partnership_name) ||
                create(:partnership, name: partnership_name)
  site.tags << partnership unless site.tags.include?(partnership)
end

Given("there is a partner called {string} in the site {string} with the partnership {string}") do |partner_name, site_name, partnership_name|
  site = Site.find_by(name: site_name)
  neighbourhood = site.neighbourhoods.first
  partnership = Partnership.find_by(name: partnership_name) ||
                create(:partnership, name: partnership_name)
  @partner = create(:partner, name: partner_name, address: create(:address, neighbourhood: neighbourhood))
  @partner.tags << partnership
end

# Server-rendered visit that works under the rack_test driver (no Capybara
# server running, so the port-based site steps above cannot be used).
When("I browse the events page for the site {string}") do |site_name|
  site = Site.find_by(name: site_name)
  visit "http://#{site.slug}.lvh.me/events"
end

When("I filter by the region {string}") do |region_name|
  within(".region-filter") { click_link(region_name) }
end

Then("the region {string} should be selected") do |region_name|
  within(".region-filter") do
    expect(page).to have_css('a[aria-current="page"]', text: region_name)
  end
end
