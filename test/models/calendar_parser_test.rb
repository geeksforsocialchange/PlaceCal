require 'test_helper'

class CalendarParserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  #
  test 'imports webcal calendars' do
    calendar = create(:calendar, name: 'Yellowbird',
                                 source: 'webcal://p24-calendars.icloud.com/published/2/WvhkIr4F3oBQrToPU-lkO6WwDTpzNTpENs-Qtbo48FhhrAfDp3gkIal2XPd5eUVO0LLERrehetRzj43c6zvbotf9_DNI6heKXBejvAkz8JQ')

    VCR.use_cassette('Yellowbird Webcal') do
      output = CalendarParser.new(calendar).parse
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal events.count, 2
      assert_equal first_event.summary, 'Age Friendly Community Soup'
      assert_equal last_event.summary, 'YellowBird Age Friendly Drop-in'
    end
  end

  test 'imports google calendars' do
    calendar = create(:calendar, name: 'Placecal Hulme & Moss Size',
                                 source: 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics')

    VCR.use_cassette('Placecal Hulme & Moss Side Google Cal') do
      output = CalendarParser.new(calendar).parse
      events = output.events
      first_event = events.first

      assert_equal events.count, 139
      assert_equal first_event.summary, 'Dementia Friends Walk and Talk Group'
      assert_equal first_event.description, 'Session run by Together Dementia Support call Sally on: 0161 2839970'
    end
  end

  test 'imports outlook calendars' do
    calendar = create(:calendar, source: 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics')

     VCR.use_cassette('Zion Centre Guide') do
       output = CalendarParser.new(calendar).parse
       events = output.events
       first_event = events.first
       last_event = events.last

       assert_equal events.count, 24
       assert_equal first_event.summary, 'Hypnotherapy'
       assert_equal last_event.summary, 'Donna - Ashtanga Yoga'
     end
  end

  test 'imports manchester u calendars' do
    calendar = create(:calendar, name: 'Martin Harris Centre',
                                 source: 'http://events.manchester.ac.uk/f3vf/calendar/tag:martin_harris_centre/view:list/p:q_details/calml.xml')

    VCR.use_cassette('Martin Harris Centre') do
      output = CalendarParser.new(calendar).parse
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal events.count, 3
      assert_equal first_event.summary, 'Technical tours of the Martin Harris Centre for Music and Drama'
      assert_equal last_event.summary, 'KIDNAP@20: The Art of Incarceration'
    end
  end

  test 'imports zarts calendars' do
    calendar = create(:calendar, name: 'Z-Arts',
                                 source: 'https://z-arts.ticketsolve.com/shows.xml')

    VCR.use_cassette('Z-Arts Calendar') do
      output = CalendarParser.new(calendar).parse
      events = output.events
      first_event = events.first
      last_event = events.last

      assert_equal events.count, 38
      assert_equal first_event.summary, 'Inuk'
      assert_equal last_event.summary, 'ZYP: Unusual Theatre in Unusual Spaces'
    end
  end

  test 'does not import if checksum is the same' do
    calendar = create(:calendar, name: 'Z-Arts',
                                 last_checksum: 'd1a94a9869af91d0548a1faf0ded91d7',
                                 source: 'https://z-arts.ticketsolve.com/shows.xml')

    VCR.use_cassette('Z-Arts Calendar') do
      output = CalendarParser.new(calendar).parse

      assert_empty output.events
    end
  end

  #TODO: for whenever facebook decides to work again
  #test 'imports facebook' do
  #end
  #
end
