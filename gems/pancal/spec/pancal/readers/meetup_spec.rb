# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/meetup_parser_spec.rb.

RSpec.describe PanCal::Readers::Meetup do
  describe '#download_calendar' do
    it 'downloads iCal data from meetup group URL' do
      meetup_url = 'https://www.meetup.com/london-bisexual-women-games-wine-group'

      VCR.use_cassette(:meetup_ical) do
        source = PanCal::Source.new(url: meetup_url)

        reader = described_class.new(source)

        data = reader.download_calendar
        expect(data).to include('BEGIN:VCALENDAR')
        expect(data).to include('BEGIN:VEVENT')
      end
    end

    it 'parses events from iCal data' do
      meetup_url = 'https://www.meetup.com/london-bisexual-women-games-wine-group'

      VCR.use_cassette(:meetup_ical) do
        source = PanCal::Source.new(url: meetup_url)

        reader = described_class.new(source)

        data = reader.download_calendar
        events = reader.import_events_from(data)

        expect(events).not_to be_empty
        expect(events.first.summary).to be_present
        expect(events.first.dtstart).to be_a(DateTime)
      end
    end

    it 'handles non-existent groups' do
      bad_url = 'https://www.meetup.com/this-group-does-not-exist-xyz123'

      VCR.use_cassette(:meetup_not_found) do
        source = PanCal::Source.new(url: bad_url)

        reader = described_class.new(source)

        expect do
          reader.download_calendar
        end.to raise_error(PanCal::InaccessibleFeed)
      end
    end
  end
end
