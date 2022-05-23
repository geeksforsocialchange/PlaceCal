require 'test_helper'
# require 'minitest/spec'

=begin

- If event location is set and calendar strategy is 'event' or 'override', that location should be used instead of the partner's place
- if event strategy is place, then it continues to work correctly
- if event strategy is override and location is not set, it continues to work correctly

1.
  event strategy
  overide strategy
  event source location is present
  address = source.location

2.
  place strategy
  address = source.location

3.
  override strategy
  address = partner.location

note:

event locations can either
  be addresses like '123 Street, place, city, postcode'
  or places like 'The Science Museum'
  or hybrids like 'Goldsmiths university, 123 street, place, etc'
  or rooms like 'Room 250, Goldsmiths university, 123 street, place, etc'
  (or URLs like 'https://zoom.com/igfjgjybviutkhy')
  or missing

=end

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
    @start_date = Date.new(1990, 1, 1)
    @end_date = Date.new(1990, 1, 2)

    @address = create(:address, neighbourhood: @neighbourhood, postcode: 'M15 5DD')

    @address_partner = create(:partner, name: 'Address Partner', address: @address)

    @notices = []
    @from_date = Date.new(1990, 1, 1)
  end

  def test_event_strategy_with_data_location_with_place_uses_partner_place
    # theory of test:
    #   given
    #     data location is present
    #     calendar strategy is 'event'
    #
    #   then
    #     use location from data
    #       (not from calendar)

    data = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: @address_partner.name,
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      has_location?: true,
      postcode: ''
    )

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(data, calendar, @notices, @from_date)

    place, address = resolver.event_strategy(calendar.place)
    assert_equal place, @address_partner
  end

  def test_event_overide_strategy_with_data_location_with_place_uses_partner_place
    # (same as above?)

    # theory of test:
    #   given
    #     data location is present
    #     calendar strategy is 'event_override'
    #   then
    #     use location from data
    #       (not from calendar)

    data = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: @address_partner.name,
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      has_location?: true,
      postcode: ''
    )

    calendar = create(:calendar, strategy: 'event_override') # <--- different strategy

    resolver = CalendarImporter::EventResolver.new(data, calendar, @notices, @from_date)

    place, address = resolver.event_strategy(calendar.place)
    assert_equal place, @address_partner
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

    data = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: @address_partner.name,
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      has_location?: true,
      postcode: ''
    )

    calendar = create(:calendar, strategy: 'place')

    resolver = CalendarImporter::EventResolver.new(data, calendar, @notices, @from_date)

    place, address = resolver.event_strategy(calendar.place)
    assert_equal place, @address_partner
  end

  def test_override_strategy_works
    # theory of test
    #   given
    #     data location is missing
    #     calendar strategy is 'event_override'
    #
    #   then
    #     event place = calendar place
    #     event address = calendar place address

    data = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: @address_partner.name,
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      has_location?: true,
      postcode: ''
    )

    calendar = create(:calendar, strategy: 'event_override')

    resolver = CalendarImporter::EventResolver.new(data, calendar, @notices, @from_date)

    place, address = resolver.event_strategy(calendar.place)
    assert_equal place, @address_partner
  end
end

=begin
describe 'EventResolver strategies' do
  # include FactoryBot::Syntax::Methods

  before do
    Address.delete_all
    Neighbourhood.delete_all
    Partner.delete_all
    Calendar.delete_all
    User.delete_all
  end

  FakeEvent = Struct.new(
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :last_modified,
    :ocurrences_between
  )

  describe 'event_strategy' do
    let(:neighbourhood) { @neighbourhood ||= FactoryBot.create(:neighbourhood, unit_code_value: 'E05011368' ) }

    let(:start_date) { Date.new(1990, 1, 1) }
    let(:end_date) { Date.new(1990, 1, 2) }

    let(:address) { FactoryBot.create(:address, neighbourhood: neighbourhood, postcode: 'M15 5DD') }
    let(:address_partner) do
      Partner.first.tap do |partner|
        partner.update! address: address
      end
      #FactoryBot.create(:partner, address: address)
    end

    describe 'with data.location' do
      describe 'with place' do
        it 'uses partner place and adress' do
          # neighbourhood =
          puts '>>>'
          #puts neighbourhood.to_json
          puts Partner.count
          puts Calendar.count

          data = FakeEvent.new(
            uid: 123,
            summary: 'A summary',
            description: 'A description',
            location: address_partner.name,
            rrule: '',
            last_modified: '',
            ocurrences_between: [[start_date, end_date]]
          )

          calendar = FactoryBot.create(:calendar)
          notices = []
          from_date = Date.new(1990, 1, 1)

          resolver = CalendarImporter::EventResolver.new(data, calendar, notices, from_date)
          place, address = resolver.event_strategy(calendar.place)

        end
      end

      describe 'with address' do
        #it 'fuzzy finds address and place'
      end

      describe 'with no place or address' do
        #it 'returns nothing'
      end
    end
    describe 'with no data.location' do
      #it 'stops processing with an exception'
    end
  end

  describe 'event_overide' do
  end

  describe 'place' do
  end

  describe 'room_number' do
  end

end
=end


