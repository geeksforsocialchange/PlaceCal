# frozen_string_literal: true

require 'test_helper'

# TODO: Assertations are wrong way around - should be (expected, actual)

class CalendarImporter::CalendarImporterTest < ActiveSupport::TestCase
  test 'imports webcal calendars' do
    url = 'webcal://p24-calendars.icloud.com/published/2/WvhkIr4F3oBQrToPU-lkO6WwDTpzNTpENs-Qtbo48FhhrAfDp3gkIal2XPd5eUVO0LLERrehetRzj43c6zvbotf9_DNI6heKXBejvAkz8JQ'

    VCR.use_cassette('Yellowbird Webcal', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Yellowbird', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal(2, events.count)
      assert_equal('Age Friendly Community Soup', first_event.summary)
      assert_equal('YellowBird Age Friendly Drop-in', last_event.summary)
    end
  end

  test 'imports google calendars' do
    url = 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics'

    VCR.use_cassette('Placecal Hulme & Moss Side Google Cal', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Placecal Hulme & Moss Size', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first

      assert_equal 139, events.count
      assert_equal 'Dementia Friends Walk and Talk Group', first_event.summary
      assert_equal 'Session run by Together Dementia Support call Sally on: 0161 2839970', first_event.description
    end
  end

  test 'imports outlook365.com calendars' do
    url = 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics'
    # skip('performance issues/no current outlook calendars')

    VCR.use_cassette('Zion Centre Guide', allow_playback_repeats: true) do
      calendar = create(:calendar, source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal 24, events.count
      assert_equal 'Hypnotherapy', first_event.summary
      assert_equal 'Donna - Ashtanga Yoga', last_event.summary
    end
  end

  test 'imports live.com calendars' do
    url = 'https://outlook.live.com/owa/calendar/1c816fe0-358f-4712-9b0f-0265edacde57/8306ff62-3b76-4ad5-8dbe-db435bfea444/cid-536CE5C17F8CF3C2/calendar.ics'

    VCR.use_cassette('ACCG', allow_playback_repeats: true) do
      calendar = create(:calendar, source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      # TODO: update these tests when the calendar is populated
      assert_equal 0, events.count
      # assert_equal 'Hypnotherapy', first_event.summary
      # assert_equal 'Donna - Ashtanga Yoga', last_event.summary
    end
  end

  test 'imports manchester u calendars' do
    url = 'http://events.manchester.ac.uk/f3vf/calendar/tag:martin_harris_centre/view:list/p:q_details/calml.xml'

    VCR.use_cassette('Martin Harris Centre', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Martin Harris Centre', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal(3, events.count)
      assert_equal('Technical tours of the Martin Harris Centre for Music and Drama', first_event.summary)
      assert_equal('KIDNAP@20: The Art of Incarceration', last_event.summary)
    end
  end

  test 'imports ticketsolve calendars' do
    url = 'https://z-arts.ticketsolve.com/shows.xml'

    VCR.use_cassette('Z-Arts Calendar', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Z-Arts', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal(38, events.count)
      assert_equal('Inuk', first_event.summary)
      assert_equal('ZYP: Unusual Theatre in Unusual Spaces', last_event.summary)
    end
  end

  test 'imports teamup calendars' do
    url = 'https://ics.teamup.com/feed/ksq8ayp7mw5mhb193x/5941140.ics'

    VCR.use_cassette('Teamup.com calendar', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Teamup.com', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal 25, events.count
      assert_equal 'Mudeford Lifeboat Fun Day', first_event.summary
      assert_equal 'BEETLE DRIVE', last_event.summary
    end
  end

  test 'imports eventbrite calendars' do
    url = 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483'

    VCR.use_cassette('Eventbrite calendar', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Eventbrite - Queer Lit & Social Refuge', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal 73, events.count
      assert_equal 'Do You Believe in Life After Loss – Andrew Flewitt in Conversation.', first_event.summary
      assert_equal 'Write That Novel: A writers workshop', last_event.summary
    end
  end

  test 'imports squarespace calendars' do
    url = 'https://robin-cunningham-dh7d.squarespace.com/our-events/'

    VCR.use_cassette('Squarespace calendar', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'VFD - squarespace', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal 16, events.count
      assert_equal 'crazinsT artisT: Before Dawn', first_event.summary
      assert_equal 'The Matrix: Dance Dance Revolutions', last_event.summary
    end
  end

  test 'imports DiceFM events from ld+json source' do
    url = 'https://dice.fm/venue/folklore-2or7'

    VCR.use_cassette(:dice_fm_events, allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'VFD - squarespace', source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events
      events = output.events

      # puts DateTime.now
      # events.each do |event|
      #   puts "#{event.start_time} '#{event.summary}' #{event.in_future?}"
      # end

      first_event = events.first
      last_event = events.last

      assert_equal 15, events.count
      assert_equal 'Kai Bosch', first_event.summary
      assert_equal 'Molly Payton', last_event.summary
    end
  end

  test 'does not import if checksum is the same' do
    url = 'https://z-arts.ticketsolve.com/shows.xml'
    checksum = 'd1a94a9869af91d0548a1faf0ded91d7'

    VCR.use_cassette('Z-Arts Calendar', allow_playback_repeats: true) do
      calendar = create(:calendar, name: 'Z-Arts', last_checksum: checksum, source: url)

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      output = parser_class.new(calendar).calendar_to_events

      assert_empty output.events
    end
  end

  test 'auto detection can pick up ld+json source' do
    url = 'https://www.heartoftorbaycic.com/events'

    VCR.use_cassette(:heart_of_torbay) do
      calendar = create(:calendar, name: 'Heart of Torbau', source: url, importer_mode: 'auto')

      parser_class = CalendarImporter::CalendarImporter.new(calendar).parser
      assert_equal 'ld-json', parser_class::KEY
    end
  end

  test 'auto detection can cope with unhandled calendar sources' do
    url = 'https://gfsc.studio' # no calendars here

    # FIXME: we need to test when a calendar has been given a valid URL
    #   (at creation) and then the URL subsequently responds with an invalid cod
    #   (like a calendar going offline)

    VCR.use_cassette(:gfsc_studio) do
      calendar = build(:calendar, name: 'GFSC Studio', source: url, importer_mode: 'auto')

      assert_raises CalendarImporter::Exceptions::UnsupportedFeed do
        CalendarImporter::CalendarImporter.new(calendar).parser
      end
    end
  end

  test 'handles bad URLs' do
    calendar = build(:calendar)

    calendar.source = ''
    assert_raises CalendarImporter::Exceptions::UnsupportedFeed do
      CalendarImporter::CalendarImporter.new(calendar)
    end

    calendar.source = 'hts://example,com'
    assert_raises CalendarImporter::Exceptions::UnsupportedFeed do
      CalendarImporter::CalendarImporter.new(calendar)
    end
  end
end
