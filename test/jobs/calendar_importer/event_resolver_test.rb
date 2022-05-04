require 'test_helper'

class EventsResolverTest < ActiveSupport::TestCase

  test "no location strategy" do
    FakeEvent = Struct.new(
      :uid,
      :summary,
      :description,
      :location,
      :rrule,
      :last_modified,
      :ocurrences_between
    )

    start_date = Date.new(1990, 1, 1)
    end_date = Date.new(1990, 1, 2)

    fake_event = FakeEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: 'A location',
      rrule: '',
      last_modified: '',
      ocurrences_between: [[start_date, end_date]]
    )

    event_data = CalendarImporter::Events::IcsEvent.new(fake_event, start_date, end_date)

    calendar = create(:calendar, strategy: 'no_location')
    notices = []
    from_date = start_date

    resolver = CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    resolver.determine_location_for_strategy

    # these are not set even if present in source
    assert_nil resolver.data.place_id
    assert_nil resolver.data.address_id

    # still sets partner
    assert_equal calendar.partner_id, resolver.data.partner_id

  end
end

