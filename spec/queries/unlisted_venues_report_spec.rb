# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnlistedVenuesReport do
  let(:partner) { create(:riverside_community_hub) }
  let(:calendar) { create(:calendar, strategy: "event") }

  def event_at(text, calendar: self.calendar, **attrs)
    create(:event, calendar:, raw_location_from_source: text, **attrs)
  end

  describe "#rows" do
    it "leaves out an event whose location matches a partner by street or name" do
      partner
      event_at("1 River Road, Millbrook ZZMB 1RS")
      event_at("Riverside Community Hub, Millbrook, ZZMB 1RS")
      event_at("Room 2, 1 River Road, ZZMB 1RS")

      report = described_class.new

      expect(report.rows).to be_empty
      expect(report.total).to eq(3)
    end

    it "lists a place calendar event whose location names another venue" do
      place_calendar = create(:place_calendar, place: partner)
      event_at("Oak Hall, 5 Elm Street, Millbrook ZZMB 2OT", calendar: place_calendar, place: partner, address: partner.address)

      row = described_class.new.rows.sole

      expect(row.values).to eq(["ZZMB 2OT", "Oak Hall", 1, 1, "Oak Hall, 5 Elm Street, Millbrook ZZMB 2OT"])
    end

    it "groups different text for the same building, counting distinct calendars" do
      other_calendar = create(:calendar)
      event_at("Oak Hall, 5 Elm Street, ZZMB 2OT")
      event_at("OAK HALL, Millbrook, zzmb 2ot")
      event_at("Oak  Hall, ZZMB 2OT", calendar: other_calendar)

      row = described_class.new.rows.sole

      expect([row.postcode, row.first_line, row.events, row.calendar_ids.size]).to eq(["ZZMB 2OT", "Oak Hall", 3, 2])
    end

    it "sorts by event count, highest first, and applies the limit" do
      event_at("Quiet Hall, ZZMB 3GF")
      2.times { event_at("Busy Hall, ZZMB 2OT") }

      expect(described_class.new.rows.map(&:first_line)).to eq(["Busy Hall", "Quiet Hall"])
      expect(described_class.new(limit: 1).rows.map(&:first_line)).to eq(["Busy Hall"])
    end

    it "leaves out past events, link-only locations and room number calendars' rooms" do
      event_at("Old Hall, ZZMB 2OT", dtstart: 1.week.ago, dtend: 1.week.ago + 1.hour)
      event_at("https://zoom.example/j/123")
      event_at("Room 4", calendar: create(:calendar, strategy: "room_number"))

      report = described_class.new

      expect(report.rows).to be_empty
      expect(report.no_postcode.events).to eq(0)
      expect(report.total).to eq(1)
    end
  end

  describe "#no_postcode" do
    it "counts events whose location has no postcode in one row" do
      event_at("The park by the river")
      event_at("Somewhere else", calendar: create(:calendar))

      report = described_class.new

      expect(report.rows).to be_empty
      expect([report.no_postcode.events, report.no_postcode.calendar_ids.size]).to eq([2, 2])
    end
  end

  describe "#to_text" do
    it "prints the summary then aligned rows, with the no postcode row last" do
      2.times { event_at("Oak Hall, ZZMB 2OT") }
      event_at("The park by the river")

      expect(described_class.new.to_text).to eq(<<~TEXT.chomp)
        Upcoming events with a location: 3
        Events at venues that match no partner: 2
        Venues that match no partner: 1
        Events with no postcode: 1

        Postcode  First line     Events  Calendars  Sample location
        ZZMB 2OT  Oak Hall            2          1  Oak Hall, ZZMB 2OT
                  (no postcode)       1          1  The park by the river
      TEXT
    end
  end

  describe "#to_csv" do
    it "writes a header row, the venues and the no postcode row" do
      event_at("Oak Hall, ZZMB 2OT")

      csv = CSV.parse(described_class.new.to_csv)

      expect(csv).to eq([
                          ["Postcode", "First line", "Events", "Calendars", "Sample location"],
                          ["ZZMB 2OT", "Oak Hall", "1", "1", "Oak Hall, ZZMB 2OT"],
                          [nil, "(no postcode)", "0", "0", nil]
                        ])
    end
  end

  it "writes nothing to the database" do
    partner
    event_at("Oak Hall, ZZMB 2OT")
    event_at("The park by the river")
    counts = -> { [Event, Address, Partner, Calendar, Neighbourhood].map(&:count) }

    expect { described_class.new.to_text }.not_to(change(&counts))
  end
end
