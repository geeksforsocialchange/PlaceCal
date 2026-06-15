# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/parser_ics_spec.rb.

RSpec.describe PanCal::Readers::Ics do
  let(:blank_source) { PanCal::Source.new(url: 'https://example.com/feed.ics') }
  let(:reader) { described_class.new(blank_source) }

  describe '#parse_remote_calendars' do
    it 'parses ICS' do
      ics_data = file_fixture('family-action-org-uk.ics').read
      events = reader.parse_remote_calendars(ics_data)

      expect(events.length).to eq(1)
    end

    it 'handles missing ICAL data' do
      expect do
        reader.parse_remote_calendars('')
      end.to raise_error(PanCal::InvalidResponse, 'Source returned empty ICS data') do |error|
        expect(error.code).to eq(:missing_data)
      end
    end

    it 'handles badly formed ICAL data' do
      bad_ics_data = file_fixture('family-action-org-uk-bad.ics').read

      expect do
        reader.parse_remote_calendars(bad_ics_data)
      end.to raise_error(PanCal::InvalidResponse, 'Could not parse ICS response (Invalid iCalendar input line: */)') do |error|
        expect(error.code).to eq(:invalid_ics)
      end
    end
  end
end

RSpec.describe 'ICS event parsing' do
  describe 'bad ICS data handling' do
    it 'catches and signals parsing bad ICS data' do
      bad_calendar_url = 'https://calendar.google.com/calendar/u/0/r?tab=rc&pli=1'

      VCR.use_cassette('Importer ICS Bad Response', allow_playback_repeats: true) do
        source = PanCal::Source.new(url: bad_calendar_url)

        reader = PanCal::Readers::Ics.new(source)

        expect do
          reader.read
        end.to raise_error(PanCal::InvalidResponse)
      end
    end
  end
end
