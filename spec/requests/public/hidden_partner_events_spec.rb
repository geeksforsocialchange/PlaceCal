# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events organised by hidden partners", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }
  let(:visible_partner) { create(:partner, address: create(:address, neighbourhood: ward)) }
  let(:hidden_partner) do
    create(:partner, address: create(:address, neighbourhood: ward), hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
  end
  let!(:visible_event) do
    create(:event, organiser: visible_partner, summary: "Visible Event", address: create(:address, neighbourhood: ward),
                   dtstart: 1.day.from_now, dtend: 1.day.from_now + 1.hour)
  end
  let!(:hidden_event) do
    create(:event, organiser: hidden_partner, summary: "Hidden Event", address: create(:address, neighbourhood: ward),
                   dtstart: 1.day.from_now, dtend: 1.day.from_now + 1.hour)
  end

  before { site.neighbourhoods << ward }

  def ical_uids
    Icalendar::Calendar.parse(response.body).first.events.map { |event| event.uid.to_s }
  end

  def uid(event) = "event-#{event.id}@placecal.org"

  describe "the directory feeds" do
    it "leaves them out of /events.ics" do
      get events_url(host: "lvh.me", format: :ics)

      expect(ical_uids).to include(uid(visible_event))
      expect(ical_uids).not_to include(uid(hidden_event))
    end

    it "leaves them out of /events.csv" do
      get events_url(host: "lvh.me", format: :csv, period: "month")

      titles = CSV.parse(response.body, headers: true).pluck("Title")
      expect(titles).to include("Visible Event")
      expect(titles).not_to include("Hidden Event")
    end

    it "drops an event from the feed once its organiser is hidden" do
      url = events_url(host: "lvh.me", format: :ics)
      get url
      etag = response.headers["ETag"]

      Timecop.freeze(1.minute.from_now) { visible_partner.update!(hidden: true, hidden_reason: "Test", hidden_blame_id: 1) }
      get url, headers: { "If-None-Match" => etag }

      expect(response).to have_http_status(:ok)
      expect(ical_uids).not_to include(uid(visible_event))
    end
  end

  describe "a site whose area holds the event's address" do
    it "leaves them out of the site's /events.ics" do
      get events_url(host: "#{site.slug}.lvh.me", format: :ics)

      expect(ical_uids).to include(uid(visible_event))
      expect(ical_uids).not_to include(uid(hidden_event))
    end

    it "leaves them out of the site's event listing" do
      get events_url(host: "#{site.slug}.lvh.me", period: "future")

      expect(response.body).to include("Visible Event")
      expect(response.body).not_to include("Hidden Event")
    end
  end

  describe "GET /events/:id" do
    it "redirects to the home page, as a hidden partner's own page does" do
      get event_url(hidden_event, host: "lvh.me")
      expect(response).to redirect_to(root_path)

      get event_url(hidden_event, host: "#{site.slug}.lvh.me", format: :ics)
      expect(response).to redirect_to(root_path)
    end

    it "still serves a visible partner's event" do
      get event_url(visible_event, host: "lvh.me", format: :ics)

      expect(ical_uids).to eq([uid(visible_event)])
    end

    it "doesn't name a hidden venue on a visible partner's event page" do
      hidden_partner.update!(name: "Secret Venue")
      at_hidden_venue = create(:event, organiser: visible_partner, place: hidden_partner, summary: "At Hidden Venue",
                                       address: create(:address, neighbourhood: ward), dtstart: 2.days.from_now)

      get event_url(at_hidden_venue, host: "#{site.slug}.lvh.me")

      expect(response.body).to include("At Hidden Venue")
      expect(response.body).not_to include("Secret Venue")
    end

    it "leaves them out of more from the organiser when held at the organiser's venue" do
      create(:event, organiser: hidden_partner, place: visible_partner, summary: "Hidden At Venue", dtstart: 2.days.from_now)
      create(:event, organiser: visible_partner, summary: "Another Visible", dtstart: 2.days.from_now)

      get event_url(visible_event, host: "lvh.me")

      expect(response.body).to include("Another Visible")
      expect(response.body).not_to include("Hidden At Venue")
    end
  end

  describe "a visible venue's partner page" do
    let!(:held_at_venue) do
      create(:event, organiser: hidden_partner, place: visible_partner, summary: "Hidden At Venue",
                     dtstart: 2.days.from_now, dtend: 2.days.from_now + 1.hour)
    end

    it "leaves them out of the venue's .ics" do
      get partner_url(visible_partner, host: "lvh.me", format: :ics)

      expect(ical_uids).to include(uid(visible_event))
      expect(ical_uids).not_to include(uid(held_at_venue))
    end

    it "leaves them out of the venue's .csv" do
      get partner_url(visible_partner, host: "lvh.me", format: :csv)

      titles = CSV.parse(response.body, headers: true).pluck("Title")
      expect(titles).to include("Visible Event")
      expect(titles).not_to include("Hidden At Venue")
    end

    it "leaves them out of the venue's event listing" do
      get partner_url(visible_partner, host: "lvh.me")

      expect(response.body).to include("Visible Event")
      expect(response.body).not_to include("Hidden At Venue")
    end
  end
end
