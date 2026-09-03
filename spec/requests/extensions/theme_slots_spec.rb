# frozen_string_literal: true

require "rails_helper"

# Every theme slot core exposes (#3368 D1, D3, D19, D22), proved once against
# the fixture engine. Core's job here is the mechanism: a registered slot
# reaches the rendered page, and a core theme renders none of it. What a slot
# looks like with real content belongs to the theme repo.
RSpec.describe "Theme slots", type: :request do
  let(:ward) { create(:riverside_ward) }

  # One themed site and one core site, shared by every example in the file.
  let!(:themed_site) { site_on("example_theme", "themed") }
  let!(:core_site) { site_on("pink", "plain") }

  # Built only by the examples that assert an event's date formats.
  let(:event) do
    organiser = create(:riverside_partner, address: create(:riverside_address, neighbourhood: ward))
    create(:event, organiser: organiser, address: nil,
                   dtstart: Time.zone.local(2022, 11, 9, 10), dtend: Time.zone.local(2022, 11, 9, 11))
  end

  def site_on(theme, slug)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me")
    site.neighbourhoods << ward
    site
  end

  def head_html
    response.body[%r{<head>.*?</head>}m]
  end

  it "renders the theme's homepage view and links its stylesheet" do
    get "http://themed.lvh.me"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Example theme fixture homepage")
    expect(response.body).to include(themed_site.name)
    expect(response.body).to match(%r{/assets/example_theme/theme-[0-9a-f]+\.css})
  end

  it "renders the theme's head component inside <head>, after the stylesheet chain" do
    get "http://themed.lvh.me"

    head = head_html
    expect(head).to match(%r{<link rel="stylesheet" href="/assets/example_theme/theme-[0-9a-f]+\.css" data-example-theme="head">})
    expect(head.index("data-example-theme")).to be > head.index('media="print"')
  end

  it "links the theme's icons and theme-color in place of core's" do
    get "http://themed.lvh.me"

    head = head_html
    expect(head).to match(%r{<link rel="icon" type="image/png" sizes="32x32" href="http://themed\.lvh\.me/assets/example_theme/icons/favicon-32x32-[0-9a-f]+\.png">})
    expect(head).to match(%r{<link rel="icon" type="image/png" sizes="16x16" href="[^"]*favicon-16x16-[0-9a-f]+\.png">})
    expect(head).to match(/<link rel="apple-touch-icon" sizes="180x180" href="[^"]*apple-touch-icon-[0-9a-f]+\.png">/)
    expect(head).to match(/<link rel="mask-icon" href="[^"]*mask-icon-[0-9a-f]+\.svg" color="#FF7AA7">/)
    expect(head).to include('<meta name="theme-color" content="#ff7aa7">')
    expect(head).not_to match(%r{href="[^"]*/assets/favicon-[0-9a-f]+\.png"})
  end

  it "uses the theme's static Open Graph image" do
    get "http://themed.lvh.me"

    head = head_html
    expect(head).to match(%r{<meta property="og:image" content="[^"]*/assets/example_theme/icons/og-[0-9a-f]+\.png">})
    expect(head).to include('<meta property="og:image:width" content="1200">')
    expect(head).to include('<meta property="og:image:height" content="675">')
    expect(head).to match(/<meta property="og:image:alt" content="#{Regexp.escape(themed_site.name)}[^"]*">/)
  end

  it "builds the web manifest from the theme's icons and colours" do
    get "http://themed.lvh.me/manifest.webmanifest"

    manifest = JSON.parse(response.body)
    icons = manifest["icons"]
    expect(icons.map { |i| i["sizes"] }).to eq(%w[192x192 512x512])
    expect(icons[0]["src"]).to match(%r{/assets/example_theme/icons/icon-192-[0-9a-f]+\.png})
    expect(icons[1]["src"]).to match(%r{/assets/example_theme/icons/icon-512-[0-9a-f]+\.png})
    expect(icons.map { |i| i["type"] }).to all(eq("image/png"))
    expect(manifest["background_color"]).to eq("#040f39")
    expect(manifest["theme_color"]).to eq("#ff7aa7")
  end

  it "renders the theme's footer instead of core's" do
    get "http://themed.lvh.me/events"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-example-theme="footer"')
    expect(response.body).not_to include('class="footer__inner')
  end

  it "renders the theme's hero standfirst" do
    get "http://themed.lvh.me/events"

    expect(response.body).to include("Fixture standfirst for events")
    expect(response.body).to include('hero__standfirst-detail">Fixture detail for events')
  end

  it "renders the theme's list headings on the index pages" do
    get "http://themed.lvh.me/events"
    expect(response.body).to include('class="list-heading">Fixture events list heading</h2>')

    get "http://themed.lvh.me/partners"
    expect(response.body).to include('class="list-heading">Fixture partners list heading</h2>')
  end

  it "renders the theme's nav call to action and menu label" do
    get "http://themed.lvh.me/events"

    expect(response.body).to include('href="https://example.org/donate"')
    expect(response.body).to include("Donate to the fixture")
    expect(response.body).to include('header__toggle-label">Menu<')
  end

  it "renders the day strip in place of the date picker, linking dated event URLs" do
    get "http://themed.lvh.me/events"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("day-strip")
    expect(response.body).to include("All upcoming")
    expect(response.body).to include("Tomorrow")
    expect(response.body).not_to include("Go to date")

    today = Time.zone.today
    expect(response.body).to include("/events/#{today.year}/#{today.month}/#{today.day}?period=day#paginator")
    expect(response.body).to include("/events?period=future#paginator")
  end

  it "keeps the selected region on the day strip links" do
    themed_site.tags << create(:partnership, name: "North")
    south = create(:partnership, name: "South")
    themed_site.tags << south

    get "http://themed.lvh.me/events?region=#{south.slug}"

    today = Time.zone.today
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "/events/#{today.year}/#{today.month}/#{today.day}?period=day&amp;region=#{south.slug}#paginator"
    )
    expect(response.body).to include("/events?period=future&amp;region=#{south.slug}#paginator")
  end

  it "applies the theme's event card date format and organiser prefix" do
    event
    get "http://themed.lvh.me/events?period=future"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("09 Nov")
    expect(response.body).to include('event__organiser-prefix">by </span>')
    expect(response.body).to include("Thu 10 Nov")
  end

  it "renders the theme's section name and ordinal page date on a show page" do
    get "http://themed.lvh.me/events/#{event.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('hero__section">Fixture events section</p>')
    expect(response.body).to include("9th November 2022")
  end

  # One negative for every slot at once: this catches a slot leaking onto core
  # sites regardless of which slot it is.
  it "renders none of the theme slots on a core site" do
    aggregate_failures "homepage and head" do
      get "http://plain.lvh.me"
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Example theme fixture homepage")
      expect(response.body).to include(core_site.description)

      head = head_html
      expect(head).not_to include("data-example-theme")
      expect(head).not_to include("example_theme/icons")
      expect(head).not_to include("mask-icon")
      expect(head).to match(%r{<link rel="icon" type="image/png" href="[^"]*/assets/favicon-[0-9a-f]+\.png">})
      expect(head).to match(%r{<link rel="apple-touch-icon" href="[^"]*/assets/apple-touch-icon-[0-9a-f]+\.png">})
      expect(head).to include('<meta property="og:image:height" content="630">')
      chain = head.scan(%r{/assets/(application|public_tailwind|themes/pink|print)-[0-9a-f]+\.css}).flatten
      expect(chain).to eq(%w[application public_tailwind themes/pink print])
    end

    aggregate_failures "index chrome" do
      event
      get "http://plain.lvh.me/events?period=future"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="footer__inner')
      expect(response.body).not_to include('data-example-theme="footer"')
      expect(response.body).not_to include("hero__standfirst")
      expect(response.body).not_to include("list-heading")
      expect(response.body).not_to include("header__cta")
      expect(response.body).not_to include("header__toggle-label")
      expect(response.body).to include("Go to date")
      expect(response.body).not_to include("day-strip")
      expect(response.body).to include(" 9 Nov")
      expect(response.body).not_to include("event__organiser-prefix")
    end

    aggregate_failures "show page and partners" do
      get "http://plain.lvh.me/events/#{event.id}"
      expect(response.body).not_to include("hero__section")
      expect(response.body).to include(" 9 Nov")

      get "http://plain.lvh.me/partners"
      expect(response.body).not_to include("list-heading")
    end
  end
end

# A theme whose own footer carries the Join link turns the nav one off
# (PlaceCal::Theme#nav_join, SiteNavigation#join_navigation). The fixture
# engine leaves nav_join at its default, so this needs its own registration.
RSpec.describe "Theme nav_join", :theme_registry, type: :request do
  let(:ward) { create(:riverside_ward) }

  def site_on(theme, slug)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me",
                         contact_email: "hello@example.org")
    site.neighbourhoods << ward
    site
  end

  def header_of(body)
    body[%r{<header.*?</header>}m].to_s
  end

  it "renders no Join link in the header nav for a theme that opts out" do
    PlaceCal::Extensions.register_theme(:no_join_theme) { |theme| theme.nav_join false }
    site_on("no_join_theme", "nojoin")

    get "http://nojoin.lvh.me/events"

    expect(response).to have_http_status(:ok)
    expect(header_of(response.body)).not_to include(I18n.t("navigation.site.join"))
    expect(header_of(response.body)).not_to include('href="/get-in-touch"')
  end

  it "renders it for a core theme on a site that takes enquiries" do
    site_on("pink", "plain")

    get "http://plain.lvh.me/events"

    expect(response).to have_http_status(:ok)
    expect(header_of(response.body)).to include(I18n.t("navigation.site.join"))
    expect(header_of(response.body)).to include('href="/get-in-touch"')
  end
end
