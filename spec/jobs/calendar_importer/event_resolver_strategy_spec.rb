# frozen_string_literal: true

require 'rails_helper'

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

RSpec.describe CalendarImporter::EventResolver do
  FakeEvent = Struct.new(
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :last_modified,
    :ocurrences_between,
    :has_location?,
    :postcode,
    keyword_init: true
  )

  let(:neighbourhood) { create(:neighbourhood, unit_code_value: 'E05011368') }
  let(:other_neighbourhood) { create(:neighbourhood, unit_code_value: 'E05000800') }
  let(:start_date) { Date.new(1990, 1, 1) }
  let(:end_date) { Date.new(1990, 1, 2) }
  let(:address) { create(:address, street_address: '123 alpha', neighbourhood: neighbourhood, postcode: 'M15 5DD') }
  let(:other_address) { create(:address, street_address: '456 beta', neighbourhood: other_neighbourhood, postcode: 'OL6 8BH') }
  let(:address_partner) { create(:partner, name: 'Address Partner', address: address) }
  let(:other_address_partner) { create(:partner, name: 'Other Address Partner', address: other_address) }
  let(:notices) { [] }
  let(:from_date) { Date.new(1990, 1, 1) }
  let(:event_data) do
    FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      rrule: '',
      last_modified: '',
      ocurrences_between: [[start_date, end_date]],
      has_location?: true,
      postcode: ''
    )
  end

  def create_calendar_with(args = {})
    VCR.use_cassette(:import_test_calendar) do
      create(:calendar, **args)
    end
  end

  describe '#event_strategy' do
    it 'with data location with place keeps address' do
      event_data.location = address_partner.name
      event_data.postcode = address_partner.address.postcode

      calendar = create_calendar_with(strategy: 'event', place: other_address_partner)

      resolver = described_class.new(event_data, calendar, notices, from_date)
      partner, address_result = resolver.event_strategy(calendar.place)

      expect(partner).to be_nil
      expect(address_result).not_to eq(address_partner.address)
      expect(address_result.street_address).to eq(event_data.location)
      expect(address_result.postcode).to eq(event_data.postcode)
    end
  end

  describe '#event_override_strategy' do
    it 'with data location with place keeps address' do
      event_data.location = address_partner.name
      event_data.postcode = address_partner.address.postcode

      calendar = create_calendar_with(strategy: 'event_override', place: other_address_partner)

      resolver = described_class.new(event_data, calendar, notices, from_date)
      partner, address_result = resolver.event_override_strategy(calendar.place)

      expect(partner).to be_nil
      expect(address_result).not_to eq(address_partner.address)
      expect(address_result.street_address).to eq(event_data.location)
      expect(address_result.postcode).to eq(event_data.postcode)
    end

    it 'works with no data location' do
      calendar = create_calendar_with(strategy: 'event_override', place: address_partner)
      resolver = described_class.new(event_data, calendar, notices, from_date)
      place, address_result = resolver.event_override_strategy(calendar.place)

      expect(place).to eq(calendar.place)
      expect(address_result).to eq(calendar.place.address)
    end

    it 'passes with no data location and no place' do
      calendar = create_calendar_with(strategy: 'event_override')
      calendar.place = nil
      resolver = described_class.new(event_data, calendar, notices, from_date)

      place, address_result = resolver.event_override_strategy(calendar.place)
      expect(place).to be_nil
      expect(address_result).to be_nil
    end
  end

  describe '#place_strategy' do
    it 'works' do
      event_data.location = address_partner.name

      calendar = create_calendar_with(strategy: 'place', place: other_address_partner)

      resolver = described_class.new(event_data, calendar, notices, from_date)

      place, address_result = resolver.place_strategy(calendar.place)

      # place comes from calendar
      expect(place).to eq(other_address_partner)

      # address comes from event data
      expect(address_result).to eq(other_address_partner.address)
    end
  end
end
