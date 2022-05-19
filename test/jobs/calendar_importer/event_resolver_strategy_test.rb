require 'test_helper'
require 'minitest/spec'

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

=end

describe 'EventResolver strategies' do
  # include FactoryBot::Syntax::Methods

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
        it 'fuzzy finds address and place'
      end

      describe 'with no place or address' do
        it 'returns nothing'
      end
    end
    describe 'with no data.location' do
      it 'stops processing with an exception'
    end
  end

  describe 'event_overide' do
  end

  describe 'place' do
  end

  describe 'room_number' do
  end

end



class FakeTest < ActiveSupport::TestCase
  test "look at db" do
    puts '***'
    puts Partner.count
    puts Calendar.count
  end
end
