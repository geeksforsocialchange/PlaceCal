require 'test_helper'

class CalendarImporterTaskTest < ActiveSupport::TestCase
  test 'it can auto-detect sources' do
    VCR.use_cassette('Placecal Hulme & Moss Side Google Cal', allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'Placecal Hulme & Moss Side',
        source: 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      calendar.reload

      assert_equal 'ical', calendar.importer_used
    end
  end

  test 'rejects unknown sources by default' do

    VCR.use_cassette('Uknown Teamup Feed', allow_playback_repeats: true) do
      # set up the calendar with faulty data that we know will trip up
      #   the validations. we are testing the importer, not the model
      calendar = create(
        :calendar,
        name: 'Unknown source calendar',
        source: 'https://not-a-real-calendar-provider.com/feed/ksq8ayp7mw5mhb193x/5941140.ics',
      )

      calendar.update calendar_state: 'in_worker'

      assert_raises CalendarImporter::CalendarImporter::UnsupportedFeed do
        importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
        importer_task.run
      end

      # assert_equal 'ical', calendar.importer_used
      assert_equal 'error', calendar.calendar_state
    end
  end

  test 'manual selection workds' do
    VCR.use_cassette('Uknown Teamup Feed', allow_playback_repeats: true) do
      # set up the calendar with faulty data that we know will trip up
      #   the validations. we are testing the importer, not the model
      calendar = create(
        :calendar,
        name: 'Unknown source calendar',
        source: 'https://not-a-real-calendar-provider.com/feed/ksq8ayp7mw5mhb193x/5941140.ics',
        importer_mode: 'ical'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'ical', calendar.importer_used
    end
  end

end