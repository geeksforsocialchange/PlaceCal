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
end
