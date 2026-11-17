# frozen_string_literal: true

require "rails_helper"

# Event location resolution strategies:
#
# - If event location is set and calendar strategy is 'event' or 'override', that location should be used instead of the partner's place
# - if event strategy is place, then it continues to work correctly
# - if event strategy is override and location is not set, it continues to work correctly
#
# event locations can either:
#   be addresses like '123 Street, place, city, postcode'
#   or places like 'The Science Museum'
#   or hybrids like 'Goldsmiths university, 123 street, place, etc'
#   or rooms like 'Room 250, Goldsmiths university, 123 street, place, etc'
#   (or URLs like 'https://zoom.com/igfjgjybviutkhy')
#   or missing

RSpec.describe CalendarImporter::LocationResolver do
  FakeEvent = Struct.new(
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :last_modified,
    :ocurrences_between,
    :location?,
    :postcode
  )

  let(:neighbourhood) { create(:neighbourhood, unit_code_value: "E05011368") }
  let(:other_neighbourhood) { create(:neighbourhood, unit_code_value: "E05000800") }
  let(:start_date) { Date.new(1990, 1, 1) }
  let(:end_date) { Date.new(1990, 1, 2) }
  let(:address) { create(:address, street_address: "123 alpha", neighbourhood:, postcode: "M15 5DD") }
  let(:other_address) { create(:address, street_address: "456 beta", neighbourhood: other_neighbourhood, postcode: "OL6 8BH") }
  let(:venue_address) { create(:address, street_address: "Community Hall", neighbourhood:, postcode: "M15 5DD") }
  let(:address_partner) { create(:partner, name: "Address Partner", address:) }
  let(:other_address_partner) { create(:partner, name: "Other Address Partner", address: other_address) }
  let(:venue_partner) { create(:partner, name: "Community Hall", address: venue_address, can_be_assigned_events: true) }
  let(:event_data) do
    FakeEvent.new(
      uid: 123,
      summary: "A summary",
      description: "A description",
      rrule: "",
      last_modified: "",
      ocurrences_between: [[start_date, end_date]],
      location?: true,
      postcode: ""
    )
  end

  def create_calendar_with(args = {})
    VCR.use_cassette(:import_test_calendar) do
      create(:calendar, **args)
    end
  end

  describe "event strategy" do
    it "builds address from event location data" do
      event_data.location = address_partner.name
      event_data.postcode = address_partner.address.postcode

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      result = resolver.resolve

      expect(result.address).not_to eq(address_partner.address)
      expect(result.address.street_address).to eq(event_data.location)
      expect(result.address.postcode).to eq(event_data.postcode)
      expect(result.match).to eq(:matched_venue)
    end

    it "matches a partner as place when address matches a can_be_assigned_events partner" do
      event_data.location = venue_partner.name
      event_data.postcode = venue_partner.address.postcode

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      result = resolver.resolve

      expect(result.place).to eq(venue_partner)
      expect(result.match).to eq(:matched_venue)
    end

    it "gives an event at its own address no place when no partner matches", :aggregate_failures do
      neighbourhood
      event_data.location = "Unknown Venue, 9 Gamma Road"
      event_data.postcode = "M15 5DD"

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address.street_address).to eq("Unknown Venue")
      expect(result.match).to eq(:event_address)
    end

    it "gives no place or address when the location can't be read", :aggregate_failures do
      event_data.location = "Somewhere nice"
      event_data.postcode = ""

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address).to be_nil
      expect(result.match).to eq(:none)
    end

    it "uses the default venue with no address when the event has no location", :aggregate_failures do
      event_data[:location?] = false
      calendar = create_calendar_with(strategy: "event", place: other_address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to eq(other_address_partner)
      expect(result.address).to be_nil
      expect(result.match).to eq(:default_location)
    end

    it "gives no place or address when the event has no location and the calendar no default venue", :aggregate_failures do
      event_data[:location?] = false
      calendar = create_calendar_with(strategy: "event")
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address).to be_nil
      expect(result.match).to eq(:none)
    end
  end

  describe "event_override strategy" do
    it "matches a partner as place when address matches" do
      event_data.location = venue_partner.name
      event_data.postcode = venue_partner.address.postcode

      calendar = create_calendar_with(strategy: "event_override", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      result = resolver.resolve

      expect(result.place).to eq(venue_partner)
      expect(result.address.street_address).to eq(event_data.location)
      expect(result.match).to eq(:matched_venue)
    end

    it "gives an event at its own address no place when no partner matches", :aggregate_failures do
      neighbourhood
      event_data.location = "Unknown Venue, 9 Gamma Road"
      event_data.postcode = "M15 5DD"

      calendar = create_calendar_with(strategy: "event_override", place: other_address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address.street_address).to eq("Unknown Venue")
      expect(result.address.postcode).to eq("M15 5DD")
      expect(result.match).to eq(:event_address)
    end

    it "keeps the default venue for an event at the venue's own address", :aggregate_failures do
      event_data.location = "123 Alpha"
      event_data.postcode = "m155dd"

      calendar = create_calendar_with(strategy: "event_override", place: address_partner)
      expect(Address.build_from_components(["123 Alpha"], "m155dd")).to be_present
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to eq(address_partner)
      expect(result.address).to eq(address_partner.address)
      expect(result.match).to eq(:default_location)
    end

    it "doesn't treat another building in the venue's postcode as the venue", :aggregate_failures do
      event_data.location = "125 Alpha"
      event_data.postcode = "M15 5DD"

      calendar = create_calendar_with(strategy: "event_override", place: address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address.street_address).to eq("125 Alpha")
      expect(result.match).to eq(:event_address)
    end

    it "falls back to the default venue when the address can't be built", :aggregate_failures do
      event_data.location = "Somewhere nice"
      event_data.postcode = ""

      calendar = create_calendar_with(strategy: "event_override", place: address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to eq(address_partner)
      expect(result.address).to eq(address_partner.address)
      expect(result.match).to eq(:default_location)
    end

    it "falls back to place when no data location" do
      calendar = create_calendar_with(strategy: "event_override", place: address_partner)
      resolver = described_class.new(calendar, event_data)
      result = resolver.resolve

      expect(result.place).to eq(calendar.place)
      expect(result.address).to eq(calendar.place.address)
      expect(result.match).to eq(:default_location)
    end

    it "returns nil when no data location and no place" do
      calendar = create_calendar_with(strategy: "event_override")
      calendar.place = nil
      resolver = described_class.new(calendar, event_data)

      result = resolver.resolve
      expect(result.place).to be_nil
      expect(result.address).to be_nil
      expect(result.match).to eq(:none)
    end
  end

  describe "reading the location text" do
    it "drops the postcode as a whole word and leaves the rest of the text alone" do
      event_data.location = "Ukrainian Centre, Age UK Hall, 12 Duke Street, Manchester M15 5DD"
      event_data.postcode = "M15 5DD"
      resolver = described_class.new(build(:calendar, strategy: "event"), event_data)

      expect(resolver.send(:event_location_components)).to eq(["Ukrainian Centre", "Age UK Hall", "12 Duke Street", "Manchester"])
    end
  end

  describe "room_number strategy" do
    it "explains that a default location is needed when the calendar has none" do
      calendar = build(:calendar, strategy: "room_number", place: nil)
      calendar.place = nil

      expect { described_class.new(calendar, event_data).resolve }
        .to raise_error(described_class::Problem, /no default location/)
    end

    it "adds the event's location as a room on the default venue's address", :aggregate_failures do
      event_data.location = "Room 2"
      calendar = create_calendar_with(strategy: "room_number", place: address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to eq(address_partner)
      expect(result.address).to be_persisted
      expect(result.address).not_to eq(address_partner.address)
      expect(result.address.street_address).to eq("Room 2")
      expect(result.match).to eq(:room)
    end

    it "uses the default venue's own address when the event has no location", :aggregate_failures do
      event_data[:location?] = false
      calendar = create_calendar_with(strategy: "room_number", place: address_partner)
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to eq(address_partner)
      expect(result.address).to eq(address_partner.address)
      expect(result.match).to eq(:default_location)
    end

    it "uses the default venue with no address when the venue has none", :aggregate_failures do
      venue = build(:partner, address: nil)
      calendar = build(:calendar, strategy: "room_number", place: venue)
      result = described_class.new(calendar, event_data.tap { |e| e.location = "Room 2" }).resolve

      expect(result).to have_attributes(place: venue, address: nil, match: :default_location)
    end
  end

  describe "place strategy" do
    it "resolves place and address from calendar" do
      event_data.location = address_partner.name

      calendar = create_calendar_with(strategy: "place", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      result = resolver.resolve

      expect(result.place).to eq(other_address_partner)
      expect(result.address).to eq(other_address_partner.address)
      expect(result.match).to eq(:default_location)
    end

    it "uses the default venue with no address when the venue has none" do
      venue = build(:partner, address: nil)
      result = described_class.new(build(:calendar, strategy: "place", place: venue), event_data).resolve

      expect(result).to have_attributes(place: venue, address: nil, match: :default_location)
    end

    it "gives no place or address when the calendar has no default venue", :aggregate_failures do
      calendar = build(:calendar, strategy: "place")
      calendar.place = nil
      result = described_class.new(calendar, event_data).resolve

      expect(result.place).to be_nil
      expect(result.address).to be_nil
      expect(result.match).to eq(:none)
    end
  end

  describe "no_location and online_only strategies" do
    %w[no_location online_only].each do |strategy|
      it "gives #{strategy} no place or address", :aggregate_failures do
        event_data.location = "Room 2"
        calendar = create_calendar_with(strategy:, place: address_partner)
        result = described_class.new(calendar, event_data).resolve

        expect(result.place).to be_nil
        expect(result.address).to be_nil
        expect(result.match).to eq(:none)
      end
    end
  end
end
