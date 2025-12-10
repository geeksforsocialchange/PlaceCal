# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarImporter::CalendarImporterTask do
  describe 'auto-detection' do
    it 'can auto-detect sources' do
      VCR.use_cassette('Placecal Hulme & Moss Side Google Cal', allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Placecal Hulme & Moss Side',
          source: 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        calendar.reload

        expect(calendar.importer_used).to eq('ical')
      end
    end
  end

  describe 'manual selection' do
    it 'works' do
      VCR.use_cassette('Uknown Teamup Feed', allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Unknown source calendar',
          source: 'https://not-a-real-calendar-provider.com/feed/ksq8ayp7mw5mhb193x/5941140.ics',
          importer_mode: 'ical'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('ical')
      end
    end
  end

  describe 'Eventbrite import' do
    it 'can import Eventbrite' do
      VCR.use_cassette(:eventbrite_events, allow_playback_repeats: true) do
        create(:eventbrite_valid_address_hood)
        calendar = create(
          :calendar,
          name: 'Eventbrite calendar',
          source: 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483',
          strategy: 'event'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('eventbrite')

        created_events = calendar.events
        expect(created_events.count).to eq(72)
      end
    end
  end

  describe 'OutSavvy import' do
    it 'can import OutSavvy (ld+json) events when manually selected' do
      VCR.use_cassette(:out_savvy_events, allow_playback_repeats: true, match_requests_on: [:host]) do
        calendar = create(
          :calendar,
          name: 'OutSavvy calendar',
          source: 'https://www.outsavvy.com/organiser/sappho-events'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('outsavvy')

        created_events = calendar.events
        expect(created_events.count).to eq(4)
      end
    end
  end

  describe 'DiceFM import' do
    it 'can import DiceFM (ld+json) events when manually selected' do
      VCR.use_cassette(:dice_fm_events, allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'DiceFM calendar',
          source: 'https://dice.fm/venue/folklore-2or7'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('ld-json')

        created_events = calendar.events
        expect(created_events.count).to eq(15)
      end
    end
  end

  describe 'generic LD+JSON import' do
    it 'can import from generic ld+json source' do
      VCR.use_cassette(:heart_of_torbay, allow_playback_repeats: true) do
        create(:ldjson_valid_address_hood)
        calendar = create(
          :calendar,
          name: 'Generic LD+JSON Calendar',
          source: 'https://www.heartoftorbaycic.com/events',
          strategy: 'event'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('ld-json')

        created_events = calendar.events
        expect(created_events.count).to eq(1)
      end
    end
  end

  describe 'error handling' do
    it 'throws inaccessible_feed exception for invalid source URLs' do
      VCR.use_cassette(:example_dot_com_bad_response) do
        calendar = build(
          :calendar,
          name: 'Generic LD+JSON Calendar',
          source: 'https://example.com/',
          strategy: 'event',
          calendar_state: 'in_worker'
        )

        expect {
          importer_task = described_class.new(calendar, Date.today, true)
          importer_task.run
        }.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed)
      end
    end

    it 'throws bad_feed_response exception for invalid responses' do
      VCR.use_cassette(:squarespace_bad_json, allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Squarespace with bad JSON',
          source: 'https://robin-cunningham-dh7d.squarespace.com/our-events',
          strategy: 'event',
          calendar_state: 'in_worker'
        )

        expect {
          importer_task = described_class.new(calendar, Date.today, true)
          importer_task.run
        }.to raise_error(CalendarImporter::Exceptions::InvalidResponse, /Source responded with invalid JSON/)
      end
    end
  end

  describe 'generic iCal import' do
    it 'can import from generic iCal feed' do
      VCR.use_cassette(:generic_ical_feed, allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Generic iCal Calendar',
          source: 'https://www.birchcommunitycentre.co.uk/events.ics',
          strategy: 'place'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('ical')

        created_events = calendar.events
        expect(created_events.count).to eq(50) # (at time of recording)
      end
    end

    it 'can import from webcal feed' do
      VCR.use_cassette(:generic_webcal_feed, allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Generic webcal Calendar',
          source: 'webcal://p14-calendars.icloud.com/published/2/MTQ2NzIwNzk1NDE0NjcyMM7jQu_vEJtKcvFoPn3S2FrA6WGkdMmCuNCcP44HV1RjEsev_l3T5lO94XkBevJwb5wd-ayWykRsarVoSJrwZvc',
          strategy: 'place'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run

        expect(calendar.calendar_state).to eq('idle')
        expect(calendar.importer_used).to eq('ical')

        created_events = calendar.events
        expect(created_events.count).to eq(52) # (at time of recording)
      end
    end
  end

  describe 'checksum handling' do
    it 'checksum date does not change on each import' do
      VCR.use_cassette('Placecal Hulme & Moss Side Google Cal', allow_playback_repeats: true) do
        calendar = create(
          :calendar,
          name: 'Placecal Hulme & Moss Side',
          source: 'https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics',
          strategy: 'place'
        )

        calendar.update calendar_state: 'in_worker'

        importer_task = described_class.new(calendar, Date.today, true)
        importer_task.run
        expect(calendar.calendar_state).to eq('idle')
        checksum_date = calendar.checksum_updated_at

        Timecop.freeze(16.days.from_now) do
          calendar.update calendar_state: 'in_worker'
          future_task = described_class.new(calendar, Date.today, true)
          future_task.run
          expect(calendar.calendar_state).to eq('idle')
        end

        expect(calendar.last_import_at).not_to eq(calendar.checksum_updated_at)
        expect(calendar.checksum_updated_at).to eq(checksum_date)
      end
    end
  end
end
