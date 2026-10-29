# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event iCal export", type: :request do
  let(:partner) { create(:riverside_partner) }

  it "gives each occurrence of an imported series its own UID" do
    events = Array.new(2) do |n|
      create(:event, organiser: partner, address: partner.address, uid: "series@example.com",
                     dtstart: (n + 1).weeks.from_now, dtend: (n + 1).weeks.from_now + 1.hour)
    end

    get partner_url(partner, host: "lvh.me", format: :ics)

    uids = Icalendar::Calendar.parse(response.body).first.events.map { |event| event.uid.to_s }
    expect(uids).to match_array(events.map { |event| "event-#{event.id}@placecal.org" })
  end

  it "covers the last week to six months ahead" do
    inside = create(:event, organiser: partner, address: partner.address, dtstart: 5.months.from_now, dtend: 5.months.from_now + 1.hour)
    beyond = create(:event, organiser: partner, address: partner.address, dtstart: 7.months.from_now, dtend: 7.months.from_now + 1.hour)

    get events_url(host: "lvh.me", format: :ics)

    expect(response.body).to include("event-#{inside.id}@placecal.org")
    expect(response.body).not_to include("event-#{beyond.id}@placecal.org")
  end

  it "includes an event with no end time, and rebuilds the feed when it changes" do
    event = create(:event, organiser: partner, address: partner.address, dtstart: 2.days.from_now, dtend: nil)
    url = events_url(host: "lvh.me", format: :ics)

    get url
    exported = Icalendar::Calendar.parse(response.body).first.events.find { |e| e.uid.to_s == "event-#{event.id}@placecal.org" }
    expect(exported).to be_present
    expect(exported.dtend).to be_nil

    etag = response.headers["ETag"]
    Timecop.freeze(1.minute.from_now) { event.update!(summary: "Renamed open-ended event") }
    get url, headers: { "If-None-Match" => etag }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Renamed open-ended event")
  end

  it "doesn't rebuild an unchanged events feed for a repeat request" do
    event = create(:event, organiser: partner, address: partner.address,
                           dtstart: 1.day.from_now, dtend: 1.day.from_now + 1.hour)
    url = events_url(host: "lvh.me", format: :ics)
    allow(Icalendar::Calendar).to receive(:new).and_call_original

    get url
    etag = response.headers["ETag"]
    get url, headers: { "If-None-Match" => etag }
    expect(response).to have_http_status(:not_modified)
    expect(Icalendar::Calendar).to have_received(:new).once

    Timecop.freeze(1.minute.from_now) { event.update!(summary: "Renamed event") }
    get url, headers: { "If-None-Match" => etag }
    expect(response.body).to include("Renamed event")
  end

  it "renders only the changed event when a feed is rebuilt" do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    events = Array.new(2) do |n|
      create(:event, organiser: partner, address: partner.address, dtstart: (n + 1).days.from_now, dtend: (n + 1).days.from_now + 1.hour)
    end
    url = events_url(host: "lvh.me", format: :ics)
    get url

    allow(Icalendar::Event).to receive(:new).and_call_original
    Timecop.freeze(1.minute.from_now) { events.first.update!(summary: "Renamed event") }
    get url

    expect(response.body).to include("Renamed event", "event-#{events.last.id}@placecal.org")
    expect(Icalendar::Event).to have_received(:new).once
  end

  it "keeps the events feed when an unrelated partner changes, and rebuilds it when its organiser does" do
    create(:event, organiser: partner, address: partner.address, dtstart: 1.day.from_now, dtend: 1.day.from_now + 1.hour)
    unrelated = create(:partner)
    url = events_url(host: "lvh.me", format: :ics)
    get url
    etag = response.headers["ETag"]

    Timecop.freeze(1.minute.from_now) { unrelated.update!(name: "Somewhere else") }
    get url, headers: { "If-None-Match" => etag }
    expect(response).to have_http_status(:not_modified)

    Timecop.freeze(2.minutes.from_now) { partner.update!(name: "Renamed organiser") }
    get url, headers: { "If-None-Match" => etag }
    expect(response).to have_http_status(:ok)
  end
end
