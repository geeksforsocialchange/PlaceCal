require 'test_helper'

class EventsImportTest < ActiveSupport::TestCase

  test 'imports webcal calendars' do

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'
    )

    VCR.use_cassette(:import_test_calendar) do
      calendar.import_events(Date.new(2018,11,20))
    end

    # pp Event.all.map {|e| [e.address_id, e.raw_location_from_source] }

    # The Old Abbey Taphouse, Guildhall Cl, Manchester M15 6SY
    # Old Abbey Taphouse, Guildhall Cl, Manchester M15 6SY
    # The Old Abbey Taphouse, Guildhall Cl, Manchester M15 6SY, UK

    " Old Abbey Taphouse, Guildhall Cl, Manchester, M15 6SY"
    # Old Abbey Taphouse, Guildhall Cl, Manchester, M15 6SY
    " Old Abbey Taphouse Guildhall Cl Manchester M15 6SY"
    # Old Abbey Taphouse Guildhall Cl Manchester M15 6SY
    " oLd AbBeY tApHoUsE, Guildhall Cl, Manchester, M15 6SY"
    # oLd AbBeY tApHoUsE, Guildhall Cl, Manchester, M15 6SY
    " Guildhall Cl, Manchester M15 6SY"
    # Guildhall Cl, Manchester M15 6SY
    " Old Abbey Taphouse, Guildhall Cl, Manchester M15 6SY UK"
    # Old Abbey Taphouse, Guildhall Cl, Manchester M15 6SY UK


    # pp Event.all
    # pp Address.all

    assert_equal 10, Event.all.count
    assert_equal 2, Address.all.count

  end

end
