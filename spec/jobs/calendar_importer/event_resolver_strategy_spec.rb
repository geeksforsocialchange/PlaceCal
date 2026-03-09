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
    :has_location?,
    :postcode
  )

  let(:neighbourhood) { create(:neighbourhood, unit_code_value: "E05011368") }
  let(:other_neighbourhood) { create(:neighbourhood, unit_code_value: "E05000800") }
  let(:start_date) { Date.new(1990, 1, 1) }
  let(:end_date) { Date.new(1990, 1, 2) }
  let(:address) { create(:address, street_address: "123 alpha", neighbourhood: neighbourhood, postcode: "M15 5DD") }
  let(:other_address) { create(:address, street_address: "456 beta", neighbourhood: other_neighbourhood, postcode: "OL6 8BH") }
  let(:venue_address) { create(:address, street_address: "Community Hall", neighbourhood: neighbourhood, postcode: "M15 5DD") }
  let(:address_partner) { create(:partner, name: "Address Partner", address: address) }
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
      has_location?: true,
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
      _place, address_result = resolver.resolve

      expect(address_result).not_to eq(address_partner.address)
      expect(address_result.street_address).to eq(event_data.location)
      expect(address_result.postcode).to eq(event_data.postcode)
    end

    it "matches a partner as place when address matches a can_be_assigned_events partner" do
      event_data.location = venue_partner.name
      event_data.postcode = venue_partner.address.postcode

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      place, _address_result = resolver.resolve

      expect(place).to eq(venue_partner)
    end

    it "returns nil place when no matching partner found" do
      event_data.location = "Unknown Venue"
      event_data.postcode = "M15 5DD"

      calendar = create_calendar_with(strategy: "event", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      place, _address_result = resolver.resolve

      expect(place).to be_nil
    end
  end

  describe "event_override strategy" do
    it "matches a partner as place when address matches" do
      event_data.location = venue_partner.name
      event_data.postcode = venue_partner.address.postcode

      calendar = create_calendar_with(strategy: "event_override", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      place, address_result = resolver.resolve

      expect(place).to eq(venue_partner)
      expect(address_result.street_address).to eq(event_data.location)
    end

    it "falls back to calendar place when no matching partner found" do
      event_data.location = "Unknown Venue"
      event_data.postcode = "M15 5DD"

      calendar = create_calendar_with(strategy: "event_override", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      place, _address_result = resolver.resolve

      expect(place).to eq(other_address_partner)
    end

    it "falls back to place when no data location" do
      calendar = create_calendar_with(strategy: "event_override", place: address_partner)
      resolver = described_class.new(calendar, event_data)
      place, address_result = resolver.resolve

      expect(place).to eq(calendar.place)
      expect(address_result).to eq(calendar.place.address)
    end

    it "returns nil when no data location and no place" do
      calendar = create_calendar_with(strategy: "event_override")
      calendar.place = nil
      resolver = described_class.new(calendar, event_data)

      place, address_result = resolver.resolve
      expect(place).to be_nil
      expect(address_result).to be_nil
    end
  end

  describe "place strategy" do
    it "resolves place and address from calendar" do
      event_data.location = address_partner.name

      calendar = create_calendar_with(strategy: "place", place: other_address_partner)

      resolver = described_class.new(calendar, event_data)
      place, address_result = resolver.resolve

      expect(place).to eq(other_address_partner)
      expect(address_result).to eq(other_address_partner.address)
    end
  end
end
