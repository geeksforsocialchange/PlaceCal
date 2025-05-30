# frozen_string_literal: true

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

  #  test 'rejects unknown sources by default' do
  #  calendars are invalid with bad URLs as they are checked on save
  #  but we do need to test that calendars that have URLs that have since become
  #  invalid are handled properly (marked as 'bad_source' state.
  #    VCR.use_cassette('Uknown Teamup Feed', allow_playback_repeats: true) do
  #      # set up the calendar with faulty data that we know will trip up
  #      #   the validations. we are testing the importer, not the model
  #      calendar = create(
  #        :calendar,
  #        name: 'Unknown source calendar',
  #        source: 'https://not-a-real-calendar-provider.com/feed/ksq8ayp7mw5mhb193x/5941140.ics'
  #      )
  #
  #      calendar.update calendar_state: 'in_worker'
  #
  #      assert_raises CalendarImporter::CalendarImporter::UnsupportedFeed do
  #        importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
  #        importer_task.run
  #      end
  #
  #      # assert_equal 'ical', calendar.importer_used
  #      assert_equal 'error', calendar.calendar_state
  #    end
  #  end

  test 'manual selection works' do
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

  test 'can import Eventbrite' do
    VCR.use_cassette(:eventbrite_events, allow_playback_repeats: true) do
      create(:eventbrite_valid_address_hood)
      calendar = create(
        :calendar,
        name: 'Eventbrite calendar',
        source: 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483',
        strategy: 'event'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'eventbrite', calendar.importer_used

      created_events = calendar.events
      assert_equal 72, created_events.count
    end
  end

  test 'can import OutSavvy (ld+json) events when manually selected' do
    VCR.use_cassette(:out_savvy_events, allow_playback_repeats: true, :match_requests_on => [:host]) do
      calendar = create(
        :calendar,
        name: 'OutSavvy calendar',
        source: 'https://www.outsavvy.com/organiser/sappho-events'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'outsavvy', calendar.importer_used

      created_events = calendar.events
      assert_equal 4, created_events.count
    end
  end

  test 'can import DiceFM (ld+json) events when manually selected' do
    VCR.use_cassette(:dice_fm_events, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'DiceFM calendar',
        source: 'https://dice.fm/venue/folklore-2or7'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'ld-json', calendar.importer_used

      created_events = calendar.events
      assert_equal 15, created_events.count
    end
  end

  test 'can import from generic ld+json source' do
    VCR.use_cassette(:heart_of_torbay, allow_playback_repeats: true) do
      create(:ldjson_valid_address_hood)
      calendar = create(
        :calendar,
        name: 'Generic LD+JSON Calendar',
        source: 'https://www.heartoftorbaycic.com/events',
        strategy: 'event'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'ld-json', calendar.importer_used

      created_events = calendar.events
      assert_equal 1, created_events.count
    end
  end

  test 'will throw innaccessible_feed exception for invalid source URLs' do
    VCR.use_cassette(:example_dot_com_bad_response) do
      calendar = build(
        :calendar,
        name: 'Generic LD+JSON Calendar',
        source: 'https://example.com/',
        strategy: 'event',
        calendar_state: 'in_worker'
      )

      assert_raises(CalendarImporter::Exceptions::InaccessibleFeed) do
        importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
        importer_task.run
      end
    end
  end

  test 'will throw bad_feed_response exception for invalid responses' do
    VCR.use_cassette(:squarespace_bad_json, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'Squarespace with bad JSON',
        source: 'https://robin-cunningham-dh7d.squarespace.com/our-events',
        strategy: 'event',
        calendar_state: 'in_worker'
      )

      error = assert_raises(CalendarImporter::Exceptions::InvalidResponse) do
        importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
        importer_task.run
      end

      assert_includes error.message, 'Source responded with invalid JSON'
    end
  end

  test 'can import from generic iCal feed' do
    VCR.use_cassette(:generic_ical_feed, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'Generic iCal Calendar',
        source: 'https://www.birchcommunitycentre.co.uk/events.ics',
        strategy: 'place'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'ical', calendar.importer_used

      created_events = calendar.events
      assert_equal 50, created_events.count # (at time of recording)
    end
  end

  test 'can import from webcal feed' do
    VCR.use_cassette(:generic_webcal_feed, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'Generic webcal Calendar',
        source: 'webcal://p14-calendars.icloud.com/published/2/MTQ2NzIwNzk1NDE0NjcyMM7jQu_vEJtKcvFoPn3S2FrA6WGkdMmCuNCcP44HV1RjEsev_l3T5lO94XkBevJwb5wd-ayWykRsarVoSJrwZvc',
        strategy: 'place'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run

      assert_equal 'idle', calendar.calendar_state
      assert_equal 'ical', calendar.importer_used

      created_events = calendar.events
      assert_equal 52, created_events.count # (at time of recording)
    end
  end

  test 'checksum date does not change on each import' do
    VCR.use_cassette('Placecal Hulme & Moss Side Google Cal', allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        name: 'Placecal Hulme & Moss Side',
        source: 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics',
        strategy: 'place'
      )

      calendar.update calendar_state: 'in_worker'

      importer_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
      importer_task.run
      assert_equal 'idle', calendar.calendar_state
      checksum_date = calendar.checksum_updated_at

      Timecop.freeze(16.days.from_now) do
        calendar.update calendar_state: 'in_worker'
        future_task = CalendarImporter::CalendarImporterTask.new(calendar, Date.today, true)
        future_task.run
        assert_equal 'idle', calendar.calendar_state
      end

      assert_not_equal calendar.last_import_at, calendar.checksum_updated_at
      assert_equal checksum_date, calendar.checksum_updated_at
    end
  end
end
