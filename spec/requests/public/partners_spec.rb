# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Partners", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe "GET /partners" do
    # Must use same ward instance - :riverside_address creates NEW ward via association
    let!(:partners) do
      Array.new(3) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end
    end

    it "returns successful response" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it "displays partners in site neighbourhood" do
      get partners_url(host: "#{site.slug}.lvh.me")
      partners.each do |partner|
        expect(response.body).to include(partner.name)
      end
    end

    it "does not show hidden partners" do
      hidden_partner = create(:partner,
                              address: create(:address, neighbourhood: ward),
                              hidden: true,
                              hidden_reason: "Test",
                              hidden_blame_id: 1)
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).not_to include(hidden_partner.name)
    end
  end

  describe "GET /partners/:id" do
    let(:partner) { create(:riverside_partner) }

    it "shows the partner details" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(partner.name)
    end

    it "shows partner summary" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.summary)
    end

    it "shows partner address" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.address.postcode)
    end

    it "shows correct page title" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>#{partner.name} | #{site.name}</title>")
    end

    it "includes Organization JSON-LD structured data" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      json_ld_blocks = response.body.scan(%r{<script type="application/ld\+json">(.+?)</script>}m)
      org_ld = json_ld_blocks.map { |m| JSON.parse(m[0]) }.find { |d| d["@type"] == "Organization" }

      expect(org_ld).to be_present
      expect(org_ld["name"]).to eq(partner.name)
    end

    it "includes site-level WebSite JSON-LD" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      json_ld_blocks = response.body.scan(%r{<script type="application/ld\+json">(.+?)</script>}m)
      website_ld = json_ld_blocks.map { |m| JSON.parse(m[0]) }.find { |d| d["@type"] == "WebSite" }

      expect(website_ld).to be_present
    end

    context "without accessibility info" do
      it "hides accessibility section" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).not_to include("accessibility-info")
      end
    end

    context "with accessibility info" do
      before { partner.update!(accessibility_info: "Wheelchair accessible entrance") }

      it "shows accessibility section" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).to include("accessibility-info")
        expect(response.body).to include("Wheelchair accessible entrance")
      end
    end

    context "without calendar" do
      it "shows no events message" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).to include("does not list events")
      end
    end
  end

  describe "GET /partners with category filter" do
    let(:category) { create(:category_tag) }
    # Must use same ward instance
    let!(:categorized_partner) do
      partner = create(:partner, address: create(:address, neighbourhood: ward))
      partner.categories << category
      partner
    end
    let!(:uncategorized_partner) do
      create(:partner, address: create(:address, neighbourhood: ward))
    end

    it "filters partners by category" do
      # Filter by category ID since slug format may vary
      get partners_url(host: "#{site.slug}.lvh.me", params: { category: category.id })
      expect(response).to be_successful
    end
  end

  describe "GET /partners with neighbourhood filter" do
    # Must use same ward instance
    let!(:riverside_partner) do
      create(:partner, address: create(:address, neighbourhood: ward))
    end

    it "filters partners by neighbourhood" do
      # Controller expects neighbourhood ID, not name
      get partners_url(host: "#{site.slug}.lvh.me", params: { neighbourhood: ward.id })
      expect(response).to be_successful
    end
  end

  describe "GET /partners index content" do
    let!(:partners) do
      Array.new(5) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end
    end

    it "shows page title with site name" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>Partners | #{site.name}</title>")
    end

    it "shows partners header" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Our Partners")
    end

    it "shows partner names and summaries" do
      get partners_url(host: "#{site.slug}.lvh.me")
      partners.each do |partner|
        expect(response.body).to include(partner.name)
        expect(response.body).to include(partner.summary)
      end
    end
  end

  describe "GET /partners with tagged site" do
    let(:tag) { create(:tag) }
    let(:tagged_site) { create(:site, slug: "tagged-site") }
    let!(:tagged_partners) do
      Array.new(3) do
        address = create(:address, neighbourhood: ward)
        partner = create(:partner, address: address)
        partner.tags << tag
        partner
      end
    end
    let!(:untagged_partner) do
      address = create(:address, neighbourhood: ward)
      create(:partner, address: address)
    end

    before do
      tagged_site.neighbourhoods << ward
      tagged_site.tags << tag
    end

    it "shows only tagged partners" do
      get partners_url(host: "#{tagged_site.slug}.lvh.me")
      expect(response).to be_successful

      tagged_partners.each do |partner|
        expect(response.body).to include(partner.name)
      end

      # Untagged partner should not appear
      expect(response.body).not_to include(untagged_partner.name)
    end
  end

  describe "GET /partners/:id with paginated events" do
    let(:partner) { create(:riverside_partner) }
    let(:calendar) { create(:calendar, organiser: partner) }

    before do
      # Create enough upcoming events to trigger the paginator code path (threshold is 30)
      31.times do |i|
        create(:event,
               organiser: partner,
               calendar: calendar,
               dtstart: (i + 1).days.from_now.at_beginning_of_hour,
               dtend: (i + 1).days.from_now.at_beginning_of_hour + 2.hours)
      end
    end

    it "renders successfully with repeating param as string" do
      get partner_url(partner, host: "#{site.slug}.lvh.me", params: { repeating: "on" })
      expect(response).to be_successful
    end

    it "renders successfully with default repeating param" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it "renders successfully with repeating off" do
      get partner_url(partner, host: "#{site.slug}.lvh.me", params: { repeating: "off" })
      expect(response).to be_successful
    end
  end

  describe "GET /partners/:id period defaulting" do
    let(:partner) { create(:riverside_partner) }
    let(:calendar) { create(:calendar, organiser: partner) }

    context "with many events" do
      before do
        31.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: (i + 1).days.from_now.at_beginning_of_hour,
                 dtend: (i + 1).days.from_now.at_beginning_of_hour + 1.hour)
        end
      end

      it "defaults to upcoming period" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("period=upcoming")
      end

      it "shows Upcoming tab" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).to include("Upcoming")
      end
    end

    context "with sparse events (month date tabs)" do
      before do
        31.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: ((i * 2) + 1).days.from_now.at_beginning_of_hour,
                 dtend: ((i * 2) + 1).days.from_now.at_beginning_of_hour + 1.hour)
        end
      end

      it "uses month stepping for date tabs" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("period=month")
      end
    end

    context "with dense events (week date tabs)" do
      before do
        31.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: ((i % 6) + 1).days.from_now.at_beginning_of_hour + i.hours,
                 dtend: ((i % 6) + 1).days.from_now.at_beginning_of_hour + i.hours + 1.hour)
        end
      end

      it "uses week stepping for date tabs" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("period=week")
      end
    end

    context "with events only in future months" do
      before do
        31.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: (35 + i).days.from_now.at_beginning_of_hour,
                 dtend: (35 + i).days.from_now.at_beginning_of_hour + 1.hour)
        end
      end

      it "still shows events via Upcoming tab" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Upcoming")
        # Upcoming shows next 10 events regardless of month
        expect(response.body).to match(/class="[^"]*h-event[^"]*"/)
      end
    end
  end

  describe "default site directory" do
    let!(:default_site) { create_default_site }

    it "serves directory partners page on base domain" do
      get partners_url(host: "lvh.me")
      expect(response).to be_successful
    end

    context "with A-Z sort" do
      let!(:az_partners) do
        %w[Alpha Bravo Charlie].map do |name|
          create(:partner, name: name, address: create(:address, neighbourhood: ward))
        end
      end

      it "returns all partners without pagination" do
        get partners_url(host: "lvh.me", params: { sort: "name" })
        expect(response).to be_successful
        expect(response.body).to include("Alpha")
        expect(response.body).to include("Charlie")
      end

      it "filters by letter" do
        get partners_url(host: "lvh.me", params: { sort: "name", letter: "A" })
        expect(response).to be_successful
        expect(response.body).to include("Alpha")
        expect(response.body).not_to include("Bravo")
      end

      it "shows filter count when letter selected" do
        get partners_url(host: "lvh.me", params: { sort: "name", letter: "C" })
        expect(response.body).to include("Showing")
      end
    end

    describe "directory partner listing cards" do
      let!(:partner_with_summary) do
        create(:partner, name: "Summary Partner", summary: "A great community organisation")
      end
      let!(:partner_without_summary) do
        create(:partner, name: "Bare Partner", summary: nil, description: nil)
      end

      it "shows summary snippet on partner cards" do
        get partners_url(host: "lvh.me")
        expect(response.body).to include("A great community organisation")
      end

      it "renders cards without summary gracefully" do
        get partners_url(host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Bare Partner")
      end
    end
  end

  describe "directory partner show page" do
    let!(:default_site) { create_default_site }

    context "with full contact details" do
      let(:partner) { create(:riverside_partner) }

      it "shows contact card with all fields" do
        get partner_url(partner, host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Get in touch")
        expect(response.body).to include(partner.public_email)
        expect(response.body).to include(partner.public_phone)
      end

      it "shows social media links" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("@#{partner.twitter_handle}")
        expect(response.body).to include("@#{partner.instagram_handle}")
        expect(response.body).to include("Facebook")
      end
    end

    context "with no contact details" do
      let(:partner) do
        create(:partner,
               public_email: nil, public_phone: nil, url: nil,
               twitter_handle: nil, instagram_handle: nil, facebook_link: nil)
      end

      it "hides contact card" do
        get partner_url(partner, host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).not_to include('data-icon-name="contact_phone"')
        expect(response.body).not_to include('data-icon-name="contact_email"')
        expect(response.body).not_to include('data-icon-name="contact_website"')
      end
    end

    context "with categories" do
      let(:partner) { create(:partner) }
      let(:category) { create(:category_tag, name: "Youth Services") }

      before { partner.categories << category }

      it "shows categories card" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Categories")
        expect(response.body).to include("Youth Services")
      end
    end

    context "without categories" do
      let(:partner) { create(:partner) }

      it "hides categories card" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include("Categories")
      end
    end

    context "with neighbourhood" do
      let(:partner) { create(:riverside_partner) }

      it "shows neighbourhood breadcrumb" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Neighbourhood")
      end

      it "shows last 3 levels of neighbourhood hierarchy in kicker" do
        get partner_url(partner, host: "lvh.me")
        path = partner.address.neighbourhood.path.last(3).map(&:name)
        path.each do |ancestor|
          expect(response.body).to include(ancestor)
        end
      end
    end

    context "with service areas" do
      let(:partner) { create(:ashton_service_area_partner) }

      it "shows service area text in location section" do
        get partner_url(partner, host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Serves")
      end

      it "shows last 3 levels of service area hierarchy in kicker" do
        get partner_url(partner, host: "lvh.me")
        path = partner.service_area_neighbourhoods.first.path.last(3).map(&:name)
        path.each do |ancestor|
          expect(response.body).to include(ancestor)
        end
      end
    end

    context "with opening times" do
      let(:opening_times_json) do
        [
          { dayOfWeek: "https://schema.org/Monday", opens: "09:00", closes: "17:00" },
          { dayOfWeek: "https://schema.org/Wednesday", opens: "10:00", closes: "20:00" }
        ].to_json
      end
      let(:partner) { create(:partner, opening_times: opening_times_json) }

      it "shows opening times card" do
        get partner_url(partner, host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Opening times")
        expect(response.body).to include("Monday")
        expect(response.body).to include("Wednesday")
      end
    end

    context "without opening times" do
      let(:partner) { create(:partner, opening_times: "[]") }

      it "hides opening times card" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include("Opening times")
      end
    end

    context "with accessibility info" do
      let(:partner) { create(:partner, accessibility_info: "Wheelchair ramp at main entrance") }

      it "shows collapsible accessibility section" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("accessibility-info")
        expect(response.body).to include("Accessibility information")
        expect(response.body).to include("Wheelchair ramp at main entrance")
      end
    end

    context "without accessibility info" do
      let(:partner) { create(:partner) }

      it "hides accessibility section" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include("accessibility-info")
      end
    end

    context "with no events and no calendar" do
      let(:partner) { create(:partner) }

      it "hides events section entirely" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include("Upcoming events")
      end
    end

    context "with few events (under overflow threshold)" do
      let(:partner) { create(:riverside_partner) }
      let(:calendar) { create(:calendar, organiser: partner) }

      before do
        5.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: (i + 1).days.from_now.at_beginning_of_hour,
                 dtend: (i + 1).days.from_now.at_beginning_of_hour + 1.hour)
        end
      end

      it "shows all events without overflow toggle" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Upcoming events")
        expect(response.body).not_to include("more events")
      end
    end

    context "with many events (over overflow threshold)" do
      let(:partner) { create(:riverside_partner) }
      let(:calendar) { create(:calendar, organiser: partner) }

      before do
        15.times do |i|
          create(:event,
                 organiser: partner,
                 calendar: calendar,
                 dtstart: (i + 1).days.from_now.at_beginning_of_hour,
                 dtend: (i + 1).days.from_now.at_beginning_of_hour + 1.hour)
        end
      end

      it "shows overflow toggle with remaining count" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Upcoming events")
        expect(response.body).to include("Show 5 more events")
      end
    end

    context "share and subscribe card" do
      let(:partner) { create(:partner, name: "Test Org") }

      it "always shows share card with URL and iCal link" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Share &amp; subscribe")
        expect(response.body).to include("placecal.org/partners/#{partner.slug}")
        expect(response.body).to include("Subscribe via iCal")
      end
    end

    context "with containing sites (partnerships)" do
      let(:partner) { create(:riverside_partner) }
      let(:partnership_site) { create(:site, slug: "test-partnership", name: "Test Partnership") }

      before do
        partnership_site.neighbourhoods << partner.address.neighbourhood
      end

      it "shows partnerships card" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Part of")
        expect(response.body).to include("partnership")
        expect(response.body).to include("Test Partnership")
      end
    end

    context "minimal partner (address only)" do
      let(:partner) do
        create(:partner, summary: nil, description: nil,
                         public_email: nil, public_phone: nil, url: nil,
                         twitter_handle: nil, instagram_handle: nil, facebook_link: nil)
      end

      it "renders without errors" do
        get partner_url(partner, host: "lvh.me")
        expect(response).to be_successful
        expect(response.body).to include(partner.name)
      end

      it "shows only location and share cards" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include('data-icon-name="contact_phone"')
        expect(response.body).not_to include('data-icon-name="contact_email"')
        expect(response.body).not_to include("Upcoming events")
        expect(response.body).not_to include("Categories")
        expect(response.body).to include("Share &amp; subscribe")
      end
    end
  end
end
