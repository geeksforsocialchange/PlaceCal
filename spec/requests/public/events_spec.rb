# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Events", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }
  # Must use same ward instance - create partner with address in our ward
  let(:address) { create(:address, neighbourhood: ward) }
  let(:partner) { create(:partner, address: address) }

  before do
    site.neighbourhoods << ward
  end

  describe "GET /events" do
    let!(:events) do
      create_list(:event, 5,
                  organiser: partner,
                  dtstart: 1.day.from_now,
                  address: address)
    end

    it "returns successful response" do
      get events_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it "displays events" do
      get events_url(host: "#{site.slug}.lvh.me")
      events.each do |event|
        expect(response.body).to include(event.summary)
      end
    end
  end

  describe "GET /events/:id" do
    let(:event) do
      create(:event,
             organiser: partner,
             summary: "Test Event",
             dtstart: 1.day.from_now,
             address: address)
    end

    it "shows the event details" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(event.summary)
    end

    it "shows partner information" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.name)
    end

    it "does not noindex upcoming events" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(%(<meta name="robots" content="noarchive">))
      expect(response.body).not_to include("noindex")
    end

    it "noindexes past events" do
      past_event = create(:event,
                          organiser: partner,
                          dtstart: 2.days.ago,
                          dtend: 2.days.ago + 1.hour,
                          address: address)
      get event_url(past_event, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(%(<meta name="robots" content="noindex, noarchive">))
    end
  end

  describe "GET /events/:id for an event not on this site" do
    # Organised by a partner in a ward the site does not own (issue #1722)
    let(:offsite_address) { create(:address, neighbourhood: create(:oldtown_ward)) }
    let(:offsite_partner) { create(:partner, address: offsite_address) }
    let(:offsite_event) do
      create(:event,
             organiser: offsite_partner,
             dtstart: 1.day.from_now,
             address: offsite_address)
    end

    it "301-redirects to the canonical directory URL" do
      get event_url(offsite_event, host: "#{site.slug}.lvh.me")
      expect(response).to redirect_to("https://placecal.org/events/#{offsite_event.id}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "still renders on the directory apex" do
      get event_url(offsite_event, host: "lvh.me")
      expect(response).to be_successful
    end

    it "preserves the format so ics feed subscriptions keep working" do
      get event_url(offsite_event, host: "#{site.slug}.lvh.me", format: :ics)
      expect(response).to redirect_to("https://placecal.org/events/#{offsite_event.id}.ics")
    end
  end

  describe "GET /events with date filter" do
    let!(:today_event) do
      create(:event,
             organiser: partner,
             summary: "Today Event",
             dtstart: Time.current.beginning_of_day + 10.hours,
             address: address)
    end
    let!(:future_event) do
      create(:event,
             organiser: partner,
             summary: "Future Event",
             dtstart: 7.days.from_now,
             address: address)
    end

    it "filters events by date" do
      get events_url(host: "#{site.slug}.lvh.me", params: { date: Date.current.to_s })
      expect(response).to be_successful
    end
  end

  describe "GET /events/:year/:month/:day" do
    let!(:event) do
      create(:event,
             organiser: partner,
             summary: "Dated Event",
             dtstart: Time.current.beginning_of_day + 10.hours,
             address: address)
    end

    # Request the .text format so the route is exercised through set_day
    # without depending on the compiled stylesheet asset pipeline.
    it "returns successful response for a valid date" do
      # Timecop freezes time to 2022-11-08
      get events_by_date_url(host: "#{site.slug}.lvh.me", year: 2022, month: 11, day: 8, format: :text)
      expect(response).to be_successful
      expect(response.body).to include("Dated Event")
    end

    it "falls back to today instead of erroring for an invalid month" do
      get events_by_date_url(host: "#{site.slug}.lvh.me", year: 2022, month: 13, day: 8, format: :text)
      expect(response).to have_http_status(:ok)
    end

    it "falls back to today instead of erroring for an invalid day" do
      get events_by_date_url(host: "#{site.slug}.lvh.me", year: 2022, month: 11, day: 32, format: :text)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /events with partner tag filtering" do
    let(:tag) { create(:tag, type: "Facility", name: "Test Facility", slug: "test-facility") }
    let(:tag_site) { create(:site, slug: "tag-site", is_published: true) }

    let(:partner_with_tag) do
      p = create(:partner, name: "Partner with tag", address: address)
      p.tags << tag
      p
    end

    let(:partner_without_tag) do
      create(:partner, name: "Partner without tag", address: address)
    end

    before do
      # Site has tag and neighbourhood
      tag_site.tags << tag
      tag_site.neighbourhoods << ward

      # Create events for tagged partner
      2.times do |n|
        create(:event,
               organiser: partner_with_tag,
               summary: "Event with tagged partner #{n}",
               dtstart: 1.hour.from_now,
               dtend: 2.hours.from_now,
               address: address)
      end

      # Create events for untagged partner
      3.times do |n|
        create(:event,
               organiser: partner_without_tag,
               summary: "Event without tagged partner #{n}",
               dtstart: 1.hour.from_now,
               dtend: 2.hours.from_now,
               address: address)
      end
    end

    it "shows only events from partners with matching tags" do
      get events_url(host: "#{tag_site.slug}.lvh.me")
      expect(response).to be_successful

      # Should show events from tagged partner
      expect(response.body).to include("Event with tagged partner")

      # Should NOT show events from untagged partner (site has tag filter)
      expect(response.body).not_to include("Event without tagged partner")
    end
  end

  describe "GET /events index content" do
    let!(:events) do
      create_list(:event, 5,
                  organiser: partner,
                  dtstart: 1.hour.from_now,
                  dtend: 2.hours.from_now,
                  address: address)
    end

    it "shows correct page title" do
      get events_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>Events | #{site.name}</title>")
    end

    it "shows events header" do
      get events_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Events")
    end
  end

  describe "GET /events/:id show content" do
    let(:event) do
      create(:event,
             organiser: partner,
             summary: "Community Workshop",
             dtstart: 1.day.from_now,
             dtend: 1.day.from_now + 2.hours,
             address: address)
    end

    it "shows event in hero section" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include("Community Workshop")
    end

    it "shows contact information section with consistent heading level" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Contact information")
      expect(response.body).to match(%r{<h3[^>]*>Contact information</h3>})
    end

    it "shows event address with consistent heading level" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Event address")
      expect(response.body).to match(%r{<h3[^>]*>Event address</h3>})
    end

    it "shows event organiser with consistent heading level" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Event organiser")
      expect(response.body).to match(%r{<h3[^>]*>Event organiser</h3>})
    end

    it "includes Event JSON-LD structured data" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      json_ld_blocks = response.body.scan(%r{<script type="application/ld\+json">(.+?)</script>}m)
      event_ld = json_ld_blocks.map { |m| JSON.parse(m[0]) }.find { |d| d["@type"] == "Event" }

      expect(event_ld).to be_present
      expect(event_ld["name"]).to eq("Community Workshop")
      expect(event_ld["startDate"]).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "includes site-level WebSite JSON-LD" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      json_ld_blocks = response.body.scan(%r{<script type="application/ld\+json">(.+?)</script>}m)
      website_ld = json_ld_blocks.map { |m| JSON.parse(m[0]) }.find { |d| d["@type"] == "WebSite" }

      expect(website_ld).to be_present
      expect(website_ld["name"]).to eq(site.name)
    end

    it "wraps event in h-event microformat" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to match(/class="[^"]*h-event[^"]*"/)
      expect(response.body).to include('class="dt-start"')
    end
  end

  describe "GET /events/:id with bad ID" do
    it "returns not found for non-existent event" do
      get event_url(99_999, host: "lvh.me")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Not found")
    end
  end

  describe "directory events" do
    it "serves directory events page on base domain" do
      get events_url(host: "lvh.me")
      expect(response).to be_successful
    end

    it "serves event page on base domain" do
      event = create(:event, organiser: partner, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")
      expect(response).to be_successful
    end

    it "shows the event date and time in the hero (issue: apex dropped when)" do
      event = create(:event,
                     organiser: partner,
                     dtstart: 1.day.from_now.change(hour: 16, min: 0),
                     dtend: 1.day.from_now.change(hour: 17, min: 0),
                     address: address)
      get event_url(event, host: "lvh.me")
      expect(response).to be_successful

      # Assert on the visible hero, not the og_title <meta>/<title> which also
      # carries the date/time — those masked the missing on-page "when".
      # Date and time render as hero chips per the directory design handoff.
      hero = Nokogiri::HTML(response.body).at_css("section.bg-foreground")
      expect(hero).to be_present
      expect(hero.text).to include(event.dtstart.strftime("%a %-e %b"))
      expect(hero.text).to include("16:00 – 17:00")
    end

    it "shows the event information card with date, time and neighbourhood" do
      event = create(:event,
                     organiser: partner,
                     dtstart: 1.day.from_now.change(hour: 16, min: 0),
                     dtend: 1.day.from_now.change(hour: 17, min: 0),
                     address: address)
      get event_url(event, host: "lvh.me")
      expect(response.body).to include("Event information")
      expect(response.body).to include(event.dtstart.strftime("%a %-e %b %Y"))
      expect(response.body).to include(ward.shortname)
    end

    it "shows the venue in the event information card, linked to the venue partner" do
      venue = create(:partner, name: "The Venue", address: address)
      event = create(:event, organiser: partner, place: venue, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")

      info = Nokogiri::HTML(response.body).css(".rounded-card").find { |c| c.text.include?("Event information") }
      expect(info).to be_present
      venue_link = info.at_css(%(a[href="#{partner_path(venue)}"]))
      expect(venue_link).to be_present
      expect(venue_link.text).to include("The Venue")
    end

    it "shows the organised-by card with a link to the organiser" do
      event = create(:event, organiser: partner, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")
      expect(response.body).to include("Organised by")
      expect(response.body).to include(partner_path(partner))
    end

    it "still titles the organiser card when the organiser has no contact details" do
      organiser = create(:partner, name: "Contactless Org", address: address,
                                   public_email: nil, public_phone: nil, url: nil,
                                   facebook_link: nil, twitter_handle: nil, instagram_handle: nil)
      event = create(:event, organiser: organiser, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")
      expect(response).to be_successful
      expect(response.body).to include("Organised by")
      expect(response.body).to include("Contactless Org")
    end

    it "shows the share card with the canonical URL and iCal link" do
      event = create(:event, organiser: partner, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")
      expect(response.body).to include("placecal.org/events/#{event.id}")
      expect(response.body).to include("Subscribe via iCal")
    end

    it "shows other upcoming events from the same organiser" do
      event = create(:event, organiser: partner, dtstart: 1.day.from_now, address: address)
      other = create(:event,
                     organiser: partner,
                     summary: "Another Organiser Event",
                     dtstart: 3.days.from_now,
                     address: address)
      get event_url(event, host: "lvh.me")
      expect(response.body).to include("Another Organiser Event")
      expect(response.body).to include(event_path(other))
    end
  end

  describe "region filter" do
    let(:region_site) { create(:site, slug: "regions") }
    let(:region_ward) { create(:riverside_ward) }
    let(:north_tag) { create(:partnership, name: "North") }
    let(:south_tag) { create(:partnership, name: "South") }
    let(:north_partner) { create(:partner, name: "North Partner", address: create(:address, neighbourhood: region_ward)) }
    let(:south_partner) { create(:partner, name: "South Partner", address: create(:address, neighbourhood: region_ward)) }

    before do
      region_site.neighbourhoods << region_ward
      region_site.tags << north_tag
      north_partner.tags << north_tag
      create(:future_event, organiser: north_partner, summary: "Northern Social")
    end

    context "when the site has one partnership tag" do
      it "does not show the region control" do
        get events_url(host: "regions.lvh.me")

        expect(response).to be_successful
        expect(response.body).not_to include("region-filter")
      end
    end

    context "when the site has two partnership tags" do
      before do
        region_site.tags << south_tag
        south_partner.tags << south_tag
        create(:future_event, organiser: south_partner, summary: "Southern Social")
      end

      it "shows the region control" do
        get events_url(host: "regions.lvh.me")

        expect(response.body).to include("region-filter")
        expect(response.body).to include("North")
      end

      it "filters events to the selected region" do
        get events_url(host: "regions.lvh.me", region: north_tag.slug)

        expect(response.body).to include("Northern Social")
        expect(response.body).not_to include("Southern Social")
      end

      it "shows every event when no region is selected" do
        get events_url(host: "regions.lvh.me")

        expect(response.body).to include("Northern Social")
        expect(response.body).to include("Southern Social")
      end

      it "ignores an unknown region slug" do
        get events_url(host: "regions.lvh.me", region: "nowhere")

        expect(response).to be_successful
        expect(response.body).to include("Northern Social")
        expect(response.body).to include("Southern Social")
      end

      it "auto-selects the period from the selected region, not the whole site" do
        # The site as a whole is busy enough to be forced into the day view,
        # while the northern region has a single event three weeks out (#3368 D7).
        25.times { |n| create(:event, organiser: south_partner, dtstart: (n % 6).days.from_now.at_noon, summary: "Busy South #{n}") }
        create(:event, organiser: north_partner, dtstart: 20.days.from_now.at_noon, summary: "Distant Northern Social")

        get events_url(host: "regions.lvh.me", region: north_tag.slug)

        expect(response).to be_successful
        expect(response.body).to include("Distant Northern Social")
      end

      it "carries the region on the site navigation links" do
        get events_url(host: "regions.lvh.me", region: north_tag.slug)

        expect(response.body).to include(%(href="/?region=#{north_tag.slug}"))
        expect(response.body).to include(%(href="/events?region=#{north_tag.slug}"))
        expect(response.body).to include(%(href="/partners?region=#{north_tag.slug}"))
      end
    end
  end
end
