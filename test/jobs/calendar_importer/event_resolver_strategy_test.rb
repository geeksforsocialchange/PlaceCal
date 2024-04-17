# frozen_string_literal: true

require 'test_helper'

#
# - If event location is set and calendar strategy is 'event' or 'override', that location should be used instead of the partner's place
# - if event strategy is place, then it continues to work correctly
# - if event strategy is override and location is not set, it continues to work correctly
#
# 1.
#   event strategy
#   overide strategy
#   event source location is present
#   address = source.location
#
# 2.
#   place strategy
#   address = source.location
#
# 3.
#   override strategy
#   address = partner.location
#
# note:
#
# event locations can either
#   be addresses like '123 Street, place, city, postcode'
#   or places like 'The Science Museum'
#   or hybrids like 'Goldsmiths university, 123 street, place, etc'
#   or rooms like 'Room 250, Goldsmiths university, 123 street, place, etc'
#   (or URLs like 'https://zoom.com/igfjgjybviutkhy')
#   or missing
#

class EventResolverStrategyTest < ActiveSupport::TestCase
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

  def setup
    @neighbourhood = create(:neighbourhood, unit_code_value: 'E05011368')
    @other_neighbourhood = create(:neighbourhood, unit_code_value: 'E05000800')

    @start_date = Date.new(1990, 1, 1)
    @end_date = Date.new(1990, 1, 2)

    @address = create(:address, street_address: '123 alpha', neighbourhood: @neighbourhood, postcode: 'M15 5DD')
    @other_address = create(:address, street_address: '456 beta', neighbourhood: @other_neighbourhood,
                                      postcode: 'OL6 8BH')

    @address_partner = create(:partner, name: 'Address Partner', address: @address)
    @other_address_partner = create(:partner, name: 'Other Address Partner', address: @other_address)

    @notices = []
    @from_date = Date.new(1990, 1, 1)

    @event_data = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      has_location?: true,
      postcode: ''
    )
  end

  def create_calendar_with(args = {})
    VCR.use_cassette(:import_test_calendar) do
      create :calendar, **args
    end
  end

  def test_event_strategy_with_data_location_with_place_keeps_address
    @event_data.location = @address_partner.name
    @event_data.postcode = @address_partner.address.postcode

    calendar = create_calendar_with(strategy: 'event', place: @other_address_partner)

    resolver = CalendarImporter::EventResolver.new(@event_data, calendar, @notices, @from_date)
    partner, address = resolver.event_strategy(calendar.place)

    assert_nil partner
    assert_not_equal address, @address_partner.address
    assert_equal address.street_address, @event_data.location
    assert_equal address.postcode, @event_data.postcode
  end

  def test_event_overide_strategy_with_data_location_with_place_keeps_address
    @event_data.location = @address_partner.name
    @event_data.postcode = @address_partner.address.postcode

    calendar = create_calendar_with(strategy: 'event_override', place: @other_address_partner) # <--- different strategy

    resolver = CalendarImporter::EventResolver.new(@event_data, calendar, @notices, @from_date)
    partner, address = resolver.event_override_strategy(calendar.place)

    assert_nil partner
    assert_not_equal address, @address_partner.address
    assert_equal address.street_address, @event_data.location
    assert_equal address.postcode, @event_data.postcode
  end

  def test_place_strategy_works
    # theory of test:
    #   given
    #     data location is address
    #     calendar strategy is 'place'
    #
    #   then
    #     event address = data address
    #     event place = calendar place

    @event_data.location = @address_partner.name

    calendar = create_calendar_with(strategy: 'place', place: @other_address_partner)

    resolver = CalendarImporter::EventResolver.new(@event_data, calendar, @notices, @from_date)

    place, address = resolver.place_strategy(calendar.place)

    # place comes from calendar
    assert_equal place, @other_address_partner

    # address comes from event data
    assert_equal address, @other_address_partner.address
  end

  def test_override_strategy_works_with_no_data_location
    # theory of test
    #   given
    #     data location is missing
    #     calendar strategy is 'event_override'
    #
    #   then
    #     event place = calendar place
    #     event address = calendar place address

    calendar = create_calendar_with(strategy: 'event_override', place: @address_partner)
    resolver = CalendarImporter::EventResolver.new(@event_data, calendar, @notices, @from_date)
    place, address = resolver.event_override_strategy(calendar.place)

    assert_equal place, calendar.place
    assert_equal address, calendar.place.address
  end

  def test_override_strategy_fails_with_no_data_location_and_no_place
    calendar = create_calendar_with(strategy: 'event_override')
    calendar.place = nil
    resolver = CalendarImporter::EventResolver.new(@event_data, calendar, @notices, @from_date)

    assert_raises CalendarImporter::EventResolver::Problem do
      resolver.event_override_strategy(calendar.place)
    end
  end
end
