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
end
