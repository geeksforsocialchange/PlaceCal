# frozen_string_literal: true

require "rails_helper"

# Theme footer slot and hero standfirst (#3368 D1, D19).
RSpec.describe "Theme footer slot and hero standfirst", type: :request do
  let(:ward) { create(:riverside_ward) }

  def site_on(theme, slug)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me")
    site.neighbourhoods << ward
    site
  end

  it "renders the theme footer instead of core's for a themed site" do
    site = site_on("example_theme", "themed")
    get "http://themed.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-example-theme="footer"')
    expect(response.body).to include(site.name)
    expect(response.body).not_to include('class="footer__inner')
    expect(response.body).to include('href="/events"')
  end

  it "keeps core's footer for other themes" do
    site_on("pink", "plain")
    get "http://plain.lvh.me/events"
    expect(response.body).to include('class="footer__inner')
    expect(response.body).not_to include('data-example-theme="footer"')
  end

  it "shows a hero standfirst only when the theme provides one" do
    site_on("example_theme", "themed")
    get "http://themed.lvh.me/events"
    expect(response.body).to include("Fixture standfirst for events")
    expect(response.body).to include('hero__standfirst-detail">Fixture detail for events')
    site_on("pink", "plain")
    get "http://plain.lvh.me/events"
    expect(response.body).not_to include("hero__standfirst")
  end
end

RSpec.describe "Theme-overridable event card and day strip formats", type: :request do
  let(:ward) { create(:riverside_ward) }

  it "applies the theme's date formats and organiser prefix on a themed site" do
    site = create(:site, slug: "themed", theme: "example_theme", url: "https://themed.lvh.me")
    site.neighbourhoods << ward
    organiser = create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward))
    create(:event, organiser: organiser, address: nil, dtstart: Time.zone.local(2022, 11, 9, 10), dtend: Time.zone.local(2022, 11, 9, 11))
    get "http://themed.lvh.me/events?period=future"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("09 Nov")
    expect(response.body).to include('event__organiser-prefix">by </span>')
    expect(response.body).to include("Thu 10 Nov")
  end

  it "keeps core's formats on other themes" do
    site = create(:site, slug: "plain", theme: "pink", url: "https://plain.lvh.me")
    site.neighbourhoods << ward
    organiser = create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward))
    create(:event, organiser: organiser, address: nil, dtstart: Time.zone.local(2022, 11, 9, 10), dtend: Time.zone.local(2022, 11, 9, 11))
    get "http://plain.lvh.me/events?period=future"
    expect(response.body).to include(" 9 Nov")
    expect(response.body).not_to include("event__organiser-prefix")
  end
end
