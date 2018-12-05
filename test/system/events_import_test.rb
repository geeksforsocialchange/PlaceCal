require 'test_helper'

class EventsImportTest < ActiveSupport::TestCase

  test 'imports webcal calendars' do

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'
    )

    partner = create(:partner, name: 'Z-ARTS')

    VCR.use_cassette(:import_test_calendar) do
      calendar.import_events(Date.new(2018,11,20))
    end

    # pp Event.all
    # pp Address.all

    # Did all events import?
    assert_equal 10, Event.all.count

    # Was only one address created by the import? (One address was created for partner.)
    assert_equal 2, Address.all.count

    # Did exactly two events get identified as being held at partner?
    assert_equal 2, Event.where( place: partner ).count

  end

end
