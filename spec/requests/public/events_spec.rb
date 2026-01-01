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
                  partner: partner,
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
             partner: partner,
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
  end

  describe "GET /events with date filter" do
    let!(:today_event) do
      create(:event,
             partner: partner,
             summary: "Today Event",
             dtstart: Time.current.beginning_of_day + 10.hours,
             address: address)
    end
    let!(:future_event) do
      create(:event,
             partner: partner,
             summary: "Future Event",
             dtstart: 7.days.from_now,
             address: address)
    end

    it "filters events by date" do
      get events_url(host: "#{site.slug}.lvh.me", params: { date: Date.current.to_s })
      expect(response).to be_successful
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
               partner: partner_with_tag,
               summary: "Event with tagged partner #{n}",
               dtstart: 1.hour.from_now,
               dtend: 2.hours.from_now,
               address: address)
      end

      # Create events for untagged partner
      3.times do |n|
        create(:event,
               partner: partner_without_tag,
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
                  partner: partner,
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
             partner: partner,
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

    it "shows contact information section" do
      get event_url(event, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("contact")
    end
  end

  describe "GET /events/:id with bad ID" do
    let!(:default_site) { create_default_site }

    it "returns not found for non-existent event" do
      get event_url(99_999, host: "lvh.me")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Not found")
    end
  end

  describe "default site redirect" do
    let!(:default_site) { create_default_site }

    it "redirects events page on base domain" do
      get events_url(host: "lvh.me")
      expect(response).to be_redirect
    end

    it "redirects event page on base domain" do
      event = create(:event, partner: partner, dtstart: 1.day.from_now, address: address)
      get event_url(event, host: "lvh.me")
      expect(response).to be_redirect
    end
  end
end
