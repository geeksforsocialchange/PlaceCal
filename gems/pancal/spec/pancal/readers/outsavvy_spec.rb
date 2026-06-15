# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/outsavvy_parser_spec.rb.

RSpec.describe PanCal::Readers::Outsavvy do
  describe '#extract_event_urls' do
    it 'extracts event URLs from organiser page with live events' do
      outsavvy_url = 'https://www.outsavvy.com/organiser/a-whole-orange'
      url_pattern = %r{^https://www\.outsavvy\.com/event/[A-Za-z0-9-]+}

      VCR.use_cassette(:outsavvy_events) do
        source = PanCal::Source.new(url: outsavvy_url)

        reader = described_class.new(source)

        data = reader.extract_event_urls(outsavvy_url)

        expect(data).to all(match(url_pattern))
      end
    end

    it 'returns empty list for organiser page with no events' do
      outsavvy_url = 'https://www.outsavvy.com/organiser/treacles'

      VCR.use_cassette(:outsavvy_no_events) do
        source = PanCal::Source.new(url: outsavvy_url)

        reader = described_class.new(source)

        data = reader.extract_event_urls(outsavvy_url)

        expect(data).to be_empty
      end
    end
  end

  describe '#download_calendar' do
    it 'gets URL of original event listing' do
      VCR.use_cassette(:outsavvy_publisher_url) do
        source = PanCal::Source.new(url: 'https://www.outsavvy.com/organiser/ldn-queer-mart')

        reader = described_class.new(source)

        data = reader.download_calendar

        consumer = PanCal::Readers::LdJson::EventConsumer.new
        consumer.consume data
        consumer.validate_events
        consumer.events

        expected = 'https://www.outsavvy.com/event/25977/ldn-queer-mart-lgbtqia-art-market'

        expect(consumer.events[0].publisher_url).to eq(expected)
      end
    end

    it 'detects cancelled events' do
      VCR.use_cassette(:outsavvy_cancelled_event) do
        source = PanCal::Source.new(url: 'https://www.outsavvy.com/organiser/a-whole-orange')

        reader = described_class.new(source)

        data = reader.download_calendar

        consumer = PanCal::Readers::LdJson::EventConsumer.new
        consumer.consume data
        consumer.events

        expect(consumer.events[18].not_cancelled?).to be(false)
      end
    end
  end
end
