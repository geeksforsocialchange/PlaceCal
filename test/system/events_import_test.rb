require 'test_helper'

class EventsImportTest < ActiveSupport::TestCase

  test 'imports webcal calendars' do

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'
    )

    # Identify partner by partner.name == event_location.street_address
    # (Automatically created address will not match event location.)
    partner1 = create(:partner, name: 'Z-aRtS')

    # Identify partner by partner.address.street_address == event_location.street_address
    # (Other automatically created fields will not match event location.)
    partner2 = create(:partner)
    partner2.address.street_address = 'MartIn HarriS cEntre for Music and Drama'
    partner2.address.save

    VCR.use_cassette(:import_test_calendar) do
      calendar.import_events(Date.new(2018,11,20))
    end

    # pp Event.all
    # pp Address.all

    # Did all events import?
    assert_equal 11, Event.all.count

    # Each partner created above will automatically create one address.
    # All other addresses should have been created by import.
    assert_equal 3, Address.all.count

    # Were the correct number of events found at each partner location?
    assert_equal 2, Event.where( place: partner1 ).count
    assert_equal 1, Event.where( place: partner2 ).count

  end

end
