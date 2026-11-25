# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocationRuleReport do
  let(:hub) { create(:riverside_community_hub) }
  let(:library) { create(:oldtown_library, can_be_assigned_events: false) }
  let(:oak_hall) { "Oak Hall, 5 Elm Street, ZZMB 1RS" }

  def calendar_with(strategy, place: nil, **attrs)
    calendar = build(:calendar, strategy:, **attrs)
    calendar.place = place
    calendar.save!(validate: false)
    calendar
  end

  def event_on(calendar, text, place: nil, address: nil, **attrs)
    event = build(:event, calendar:, organiser: calendar&.organiser || create(:partner), raw_location_from_source: text, place:, address:, **attrs)
    event.save!(validate: false)
    event
  end

  def oak_hall_address
    create(:address, street_address: "Oak Hall", street_address2: "5 Elm Street", city: "Millbrook", postcode: "ZZMB 1RS")
  end

  before do
    create(:riverside_ward)
    hub
  end

  describe ".carried_over" do
    it "keeps the default location except for calendars with no location, and sets the room flag for room numbers", :aggregate_failures do
      expect(described_class.carried_over(build(:calendar, strategy: "place", place: hub))).to eq([hub, false])
      expect(described_class.carried_over(build(:calendar, strategy: "event_override", place: hub))).to eq([hub, false])
      expect(described_class.carried_over(build(:calendar, strategy: "room_number", place: hub))).to eq([hub, true])
      expect(described_class.carried_over(build(:calendar, strategy: "event", place: hub))).to eq([hub, false])
      expect(described_class.carried_over(build(:calendar, strategy: "event", place: nil))).to eq([nil, false])
      expect(described_class.carried_over(build(:calendar, strategy: "no_location", place: hub))).to eq([nil, false])
      expect(described_class.carried_over(build(:calendar, strategy: "online_only", place: hub))).to eq([nil, false])
    end
  end

  describe "#changes" do
    it "lists a place calendar event whose own address is somewhere else", :aggregate_failures do
      event = event_on(calendar_with("place", place: hub), oak_hall, place: hub, address: hub.address)

      change = described_class.new.changes.sole

      expect(change.event).to eq(event)
      expect(change.current.to_s).to eq("Riverside Community Hub, 1 River Road, ZZMB 1RS")
      expect(change.new.to_s).to eq("Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS")
      expect(change.kind).to eq("place and address")
    end

    it "leaves out events the rule places where they are now" do
      event_on(calendar_with("place", place: hub), "", place: hub, address: hub.address)
      event_on(calendar_with("event_override", place: hub), oak_hall, address: oak_hall_address)
      event_on(calendar_with("event", place: hub), oak_hall, address: oak_hall_address)
      room = create(:address, street_address: "Room 4", street_address2: "1 River Road", postcode: "ZZMB 1RS")
      event_on(calendar_with("room_number", place: hub), "Room 4", place: hub, address: room)
      event_on(calendar_with("event"), "")
      event_on(calendar_with("online_only"), "https://zoom.example/j/123")

      report = described_class.new

      expect(report.changes).to be_empty
      expect(report.checked).to eq(6)
    end

    it "lists a place calendar event whose text names the default location, as an address change" do
      event_on(calendar_with("place", place: hub), "Riverside Community Hub, 1 River Road, ZZMB 1RS", place: hub, address: hub.address)

      change = described_class.new.changes.sole

      expect([change.new.to_s, change.kind]).to eq(["Riverside Community Hub, Riverside Community Hub, 1 River Road, Millbrook, ZZMB 1RS", "address"])
    end

    it "lists an event calendar event that gains its default location" do
      library
      event_on(calendar_with("event", place: library), "The park by the river")

      change = described_class.new.changes.sole

      expect([change.current.to_s, change.new.to_s, change.kind]).to eq(["(none)", "Oldtown Library, 10 Heritage Lane, ZZMB 2OT", "place and address"])
    end

    it "lists a no location calendar event that gains its own address" do
      event_on(calendar_with("no_location", place: hub), oak_hall)

      change = described_class.new.changes.sole

      expect([change.new.to_s, change.kind]).to eq(["Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS", "address"])
    end

    it "lists a room number event whose room the rule reads differently" do
      event_on(calendar_with("room_number", place: hub), oak_hall, address: oak_hall_address)

      change = described_class.new.changes.sole

      expect(change.new.to_s).to eq("Riverside Community Hub, Oak Hall, 5 Elm Street, ZZMB 1RS, 1 River Road, ZZMB 1RS")
    end
  end

  describe "comparing addresses" do
    it "leaves out an address that prints the same, even with a line moved into the city" do
      old = create(:address, street_address: "Oak Hall", street_address2: "Millbrook", city: nil, postcode: "ZZMB 1RS")
      event_on(calendar_with("event"), "Oak Hall, Millbrook, ZZMB 1RS", address: old)

      expect(described_class.new.changes).to be_empty
    end

    it "lists an old address with no city when the new one prints a city" do
      old = create(:address, street_address: "Oak Hall", street_address2: "5 Elm Street", city: nil, postcode: "ZZMB 1RS")
      event_on(calendar_with("event"), oak_hall, address: old)

      change = described_class.new.changes.sole

      expect([change.current.to_s, change.new.to_s, change.kind]).to eq(["Oak Hall, 5 Elm Street, ZZMB 1RS", "Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS", "address"])
    end

    it "shows no venue name for a hidden place, now or under the rule", :aggregate_failures do
      hub.update!(hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
      event_on(calendar_with("place", place: hub), "", place: hub, address: hub.address)

      report = described_class.new

      expect(report.changes).to be_empty
      expect(report.checked).to eq(1)
    end

    it "lists an event whose hidden place gives way to a visible venue" do
      library = create(:oldtown_library)
      library.update!(hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
      event_on(calendar_with("event"), "Riverside Community Hub, 1 River Road, ZZMB 1RS", place: library, address: library.address)

      change = described_class.new.changes.sole

      expect([change.current.place, change.new.place]).to eq([nil, hub])
    end
  end

  describe "#by_strategy" do
    it "counts events, place changes and address only changes for each strategy" do
      calendar = calendar_with("place", place: hub)
      event_on(calendar, oak_hall, place: hub, address: hub.address)
      event_on(calendar, "Riverside Community Hub, 1 River Road, ZZMB 1RS", place: hub, address: hub.address)
      event_on(calendar, "", place: hub, address: hub.address)
      event_on(calendar_with("no_location"), "")

      counts = described_class.new.by_strategy.transform_values { |count| [count.events, count.place_changes, count.address_changes] }

      expect(counts).to eq("place" => [3, 1, 1], "no_location" => [1, 0, 0])
    end
  end

  describe "#without_location" do
    it "counts events the rule leaves with nothing, by whether the organiser has an address" do
      event_on(calendar_with("no_location"), "")
      organiser = build(:partner, address: nil)
      organiser.service_area_neighbourhoods << create(:neighbourhood)
      organiser.save!
      event_on(calendar_with("online_only", organiser:), "https://zoom.example/j/123")
      event_on(calendar_with("place", place: hub), "", place: hub, address: hub.address)

      expect(described_class.new.without_location).to eq(organiser_address: 1, no_organiser_address: 1)
    end
  end

  it "counts events with no calendar without checking them", :aggregate_failures do
    event_on(nil, oak_hall, address: hub.address)

    report = described_class.new

    expect([report.no_calendar, report.checked, report.changes]).to eq([1, 0, []])
  end

  it "counts events whose postcode couldn't be looked up instead of listing them", :aggregate_failures do
    event_on(calendar_with("no_location"), oak_hall)
    allow(PostcodeLookup).to receive(:call).and_raise(PostcodeLookup::Unavailable)

    report = described_class.new

    expect([report.lookup_unavailable, report.checked, report.changes]).to eq([1, 0, []])
  end

  it "looks each postcode up once" do
    2.times { event_on(calendar_with("no_location"), oak_hall) }
    event_on(calendar_with("no_location"), "Elm Hall, ZZMB 1RS")
    allow(Geocoder).to receive(:search).and_call_original

    described_class.new.changes

    expect(Geocoder).to have_received(:search).once
  end

  describe "#to_text" do
    it "prints the totals, the strategy table and each calendar's changes, place changes first and one line per series" do
      calendar = calendar_with("no_location", name: "Hub Calendar")
      first = event_on(calendar, oak_hall, summary: "Yoga")
      second = event_on(calendar, oak_hall, summary: "Yoga")
      third = event_on(calendar, "", summary: "Choir")
      at_hub = event_on(calendar, "Riverside Community Hub, 1 River Road, ZZMB 1RS", summary: "Quiz")

      expect(described_class.new.to_text).to eq(<<~TEXT.chomp)
        Upcoming events checked: 4
        Would change: 3 (place: 1, address only: 2)
        No place or address under the rule: 1 (organiser has an address: 1, organiser has none: 0)
        Not checked, no calendar: 0
        Not checked, postcode lookup unavailable: 0

        Strategy     Events  Place changes  Address only
        no_location       4              1             2

        Calendar #{calendar.id}: Hub Calendar (no_location), 3 events
          [place] Quiz (event #{at_hub.id}): (none) -> Riverside Community Hub, Riverside Community Hub, 1 River Road, Millbrook, ZZMB 1RS
          [address] Yoga (events #{first.id}, #{second.id}): (none) -> Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS
      TEXT
      expect(third).to be_persisted
    end
  end

  describe "#to_csv" do
    it "writes a row per changed event and keeps cells from being read as formulas", :aggregate_failures do
      calendar = calendar_with("no_location", name: "Hub Calendar")
      event = event_on(calendar, oak_hall, summary: "=HYPERLINK(\"http://x\")")

      expect(CSV.parse(described_class.new.to_csv)).to eq([
                                                            LocationRuleReport::HEADERS,
                                                            [event.id.to_s, "'=HYPERLINK(\"http://x\")", calendar.id.to_s, "Hub Calendar", "no_location", "address",
                                                             "(none)", "Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS"]
                                                          ])
    end
  end

  it "escapes CSV cells that start with a tab or a carriage return", :aggregate_failures do
    calendar = calendar_with("no_location")
    event_on(calendar, oak_hall, summary: "\tTab")
    event_on(calendar, oak_hall, summary: "\rReturn")

    summaries = CSV.parse(described_class.new.to_csv).drop(1).map { |row| row[1] }

    expect(summaries).to contain_exactly("'\tTab", "'\rReturn")
  end

  it "writes nothing to the database" do
    event_on(calendar_with("no_location"), oak_hall)
    event_on(calendar_with("room_number", place: hub), "Room 4", place: hub, address: hub.address)
    counts = -> { [Event, Address, Partner, Calendar, Neighbourhood].map(&:count) }

    expect do
      described_class.new.to_text
      described_class.new.to_csv
    end.not_to(change(&counts))
  end

  it "refuses to write while it runs" do
    event_on(calendar_with("no_location"), oak_hall)
    allow(CalendarImporter::LocationRule).to(receive(:new).and_wrap_original { |original, **args| original.call(**args, save: true) })

    expect { described_class.new.to_text }.to raise_error(ActiveRecord::ReadOnlyError)
  end
end
