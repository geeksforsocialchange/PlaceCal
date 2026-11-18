# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::EventRow, type: :component do
  let(:event) do
    double(id: 1, summary: "Birds Exhibition", dtstart: Time.zone.parse("2026-11-28 10:00"), dtend: Time.zone.parse("2026-11-28 17:00"),
           organiser: nil, partner_at_location: nil, address: nil, rrule: nil, online_address: nil)
  end

  it "shows the time range of an event of 3 days or less" do
    render_inline(described_class.new(event:))

    expect(page).to have_text("10am – 5pm")
  end

  it "says when a long-running event runs until in place of its times" do
    allow(event).to receive(:dtend).and_return(Time.zone.parse("2027-01-17 17:00"))
    render_inline(described_class.new(event:))

    expect(page).to have_text("From 28 Nov 2026 until 17 Jan 2027")
    expect(page).to have_no_text("10am")
  end

  it "leaves the start's year out when it ends in the same year" do
    allow(event).to receive(:dtend).and_return(Time.zone.parse("2026-12-20 17:00"))
    render_inline(described_class.new(event:))

    expect(page).to have_text("From 28 Nov until 20 Dec 2026")
  end
end
