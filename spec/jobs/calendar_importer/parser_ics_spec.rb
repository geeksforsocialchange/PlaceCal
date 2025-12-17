# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarImporter::Parsers::Ics do
  let(:blank_calendar) { Calendar.new }
  let(:parser) { described_class.new(blank_calendar) }

  describe '#parse_remote_calendars' do
    it 'parses ICS' do
      ics_data = file_fixture('family-action-org-uk.ics').read
      events = parser.parse_remote_calendars(ics_data)

      expect(events.length).to eq(1)
    end

    it 'handles missing ICAL data' do
      expect do
        parser.parse_remote_calendars('')
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, 'Source returned empty ICS data')
    end

    it 'handles badly formed ICAL data' do
      bad_ics_data = file_fixture('family-action-org-uk-bad.ics').read

      expect do
        parser.parse_remote_calendars(bad_ics_data)
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, 'Could not parse ICS response (Invalid iCalendar input line: */)')
    end
  end
end

RSpec.describe 'ICS event parsing' do
  describe 'bad ICS data handling' do
    it 'catches and signals parsing bad ICS data' do
      bad_calendar_url = 'https://calendar.google.com/calendar/u/0/r?tab=rc&pli=1'

      VCR.use_cassette('Importer ICS Bad Response', allow_playback_repeats: true) do
        calendar = create(:calendar, source: bad_calendar_url)
        args = {
          url: bad_calendar_url,
          from: Time.zone.today
        }

        parser = CalendarImporter::Parsers::Ics.new(calendar, args)

        expect do
          parser.calendar_to_events
        end.to raise_error(CalendarImporter::Exceptions::InvalidResponse)
      end
    end
  end
end
