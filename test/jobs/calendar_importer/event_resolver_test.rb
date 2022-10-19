# frozen_string_literal: true

require 'test_helper'

class EventsResolverTest < ActiveSupport::TestCase
  FakeICSEvent = Struct.new(
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :last_modified,
    :ocurrences_between,
    :custom_properties,
    # Fixes bug where entire argument to .new ended up under the uid value lmao
    # Who knew our importer was *that* robust?!
    keyword_init: true
  )

  FakeEventbriteEvent = Struct.new(
    :id,
    :name,
    :description,
    :venue,
    :start,
    :end,
    :online_event,
    :url,
    keyword_init: true
  )

  FakeMeetupEvent = Struct.new(
    :id,
    :name,
    :description,
    :link,
    :venue,
    :time,
    :utc_offset,
    :duration,
    :is_online_event,
    keyword_init: true
  )

  setup do
    @start_date = DateTime.new(1990, 1, 1, 10, 30)
    @end_date = DateTime.new(1990, 1, 2, 11, 40)

    @fake_ics_event = FakeICSEvent.new(
      uid: 123,
      summary: 'A summary',
      description: 'A description',
      location: 'A location',
      rrule: '',
      last_modified: '',
      ocurrences_between: [[@start_date, @end_date]],
      custom_properties: {}
    )

    @fake_eventbrite_event = FakeEventbriteEvent.new(
      id: '111111111111',
      name: { text: 'A summary' },
      description: { text: 'A description' },
      venue: nil,
      start: { local: @start_date.iso8601 },
      end: { local: @end_date.iso8601 },
      online_event: true
    )

    @fake_meetup_event = FakeMeetupEvent.new(
      id: '111111111',
      name: { text: 'A summary' },
      description: { text: '<p>This is a meetup description!</p>' },
      venue: nil,
      time: @start_date.to_i,
      utc_offset: (@end_date.to_i - @start_date.to_i),
      is_online_event: true
    )

    @ics_event_data = CalendarImporter::Events::IcsEvent.new(@fake_ics_event, @start_date, @end_date)
  end

  test 'online only strategy' do
    calendar = create(:calendar, strategy: 'online_only')
    notices = []
    from_date = @start_date

    resolver = CalendarImporter::EventResolver.new(@ics_event_data, calendar, notices, from_date)
    resolver.determine_location_for_strategy

    # these are not set even if present in source
    assert_nil resolver.data.place_id
    assert_nil resolver.data.address_id

    # still sets partner
    assert_equal calendar.partner_id, resolver.data.partner_id
  end

  test 'no location strategy' do
    calendar = create(:calendar, strategy: 'no_location')
    notices = []
    from_date = @start_date

    resolver = CalendarImporter::EventResolver.new(@ics_event_data, calendar, notices, from_date)
    resolver.determine_location_for_strategy

    # these are not set even if present in source
    assert_nil resolver.data.place_id
    assert_nil resolver.data.address_id

    # still sets partner
    assert_equal calendar.partner_id, resolver.data.partner_id
  end

  test 'ics: can detect google meet url in custom properties' do
    meet_link = 'https://meet.google.com/aaa-aaaa-aaa'
    @fake_ics_event[:custom_properties] = { 'x_google_conference' => [meet_link] }
    ics_event_data = CalendarImporter::Events::IcsEvent.new(@fake_ics_event, @start_date, @end_date)

    calendar = create(:calendar, strategy: 'event') # strategy doesn't matter TBH

    resolver = CalendarImporter::EventResolver.new(ics_event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, @fake_ics_event['custom_properties']['x_google_conference'].first
  end

  test 'ics: can detect jitsi link in description' do
    jitsi_link = 'https://meet.jit.si/blahblabladsf'
    @fake_ics_event[:description] = "Join us on jitsi: #{jitsi_link} words words words"
    ics_event_data = CalendarImporter::Events::IcsEvent.new(@fake_ics_event, @start_date, @end_date)

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(ics_event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, jitsi_link
  end

  test 'ics: can detect google meet link in description' do
    meet_link = 'https://meet.google.com/aaa-aaaa-aaa'
    @fake_ics_event[:description] = "Join us on meets: #{meet_link} words words words"
    ics_event_data = CalendarImporter::Events::IcsEvent.new(@fake_ics_event, @start_date, @end_date)

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(ics_event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, meet_link
  end

  test 'ics: can detect zoom link in description' do
    zoom_link = 'https://us04web.zoom.us/j/78434510758?pwd=aILSsYSJRSb_uO87tFjulZuLAA0eXT.1'
    @fake_ics_event[:description] = "join us on zoom: <p>#{zoom_link}<p> words words words"
    ics_event_data = CalendarImporter::Events::IcsEvent.new(@fake_ics_event, @start_date, @end_date)

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(ics_event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, zoom_link
  end

  test 'eventbrite: can detect online event url' do
    eventbrite_link = 'https://www.eventbrite.co.uk/e/some-random-event-woo-hoo-111111111111'
    @fake_eventbrite_event[:url] = eventbrite_link
    event_data = CalendarImporter::Events::EventbriteEvent.new(@fake_eventbrite_event)

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, eventbrite_link
  end

  test 'meetup: can detect online event url' do
    meetup_link = 'https://www.meetup.co.uk/e/some-random-event-woo-hoo-111111111111'
    @fake_meetup_event[:link] = meetup_link
    event_data = CalendarImporter::Events::MeetupEvent.new(@fake_meetup_event)

    calendar = create(:calendar, strategy: 'event')

    resolver = CalendarImporter::EventResolver.new(event_data, calendar, [], @start_date)
    resolver.determine_online_location

    assert_predicate resolver.data.online_address_id, :present?

    online_address = OnlineAddress.find(resolver.data.online_address_id)
    assert_equal online_address.url, meetup_link
  end
end
