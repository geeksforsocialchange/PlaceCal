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

  {
    %w[2026-11-24 2026-11-28] => "From 24 until 28 Nov",
    %w[2027-11-24 2027-11-28] => "From 24 until 28 Nov 2027",
    %w[2026-11-24 2027-11-28] => "From 24 Nov until 28 Nov 2027",
    %w[2027-11-28 2027-12-17] => "From 28 Nov until 17 Dec 2027",
    %w[2027-11-28 2028-01-17] => "From 28 Nov 2027 until 17 Jan 2028"
  }.each do |(from, to), text|
    it "reads #{text.inspect} in Nov 2026 for #{from} to #{to}" do
      allow(event).to receive_messages(dtstart: Time.zone.parse("#{from} 10:00"), dtend: Time.zone.parse("#{to} 17:00"))
      Timecop.travel(Time.zone.local(2026, 11, 1)) { render_inline(described_class.new(event:)) }

      expect(page).to have_text(text)
    end
  end

  it "leaves out the year of a date in the current year" do
    allow(event).to receive(:dtend).and_return(Time.zone.parse("2026-12-20 17:00"))
    Timecop.travel(Time.zone.local(2026, 11, 1)) { render_inline(described_class.new(event:)) }

    expect(page).to have_text("From 28 Nov until 20 Dec")
    expect(page).to have_no_text("2026")
  end
end
