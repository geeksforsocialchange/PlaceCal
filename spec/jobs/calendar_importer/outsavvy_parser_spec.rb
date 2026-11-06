# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Outsavvy do
  describe "#extract_event_urls" do
    it "extracts event URLs from organiser page with live events" do
      outsavvy_url = "https://www.outsavvy.com/organiser/a-whole-orange"
      url_pattern = %r{^https://www\.outsavvy\.com/event/[A-Za-z0-9-]+}

      VCR.use_cassette(:outsavvy_events) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: outsavvy_url
        )

        parser = described_class.new(calendar, url: outsavvy_url)

        data = parser.extract_event_urls(outsavvy_url)

        expect(data).to all(match(url_pattern))
      end
    end

    it "returns empty list for organiser page with no events" do
      outsavvy_url = "https://www.outsavvy.com/organiser/treacles"

      VCR.use_cassette(:outsavvy_no_events) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: outsavvy_url
        )

        parser = described_class.new(calendar, url: outsavvy_url)

        data = parser.extract_event_urls(outsavvy_url)

        expect(data).to be_empty
      end
    end
  end

  describe "#download_calendar" do
    it "gets URL of original event listing" do
      VCR.use_cassette(:outsavvy_publisher_url) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: "https://www.outsavvy.com/organiser/ldn-queer-mart"
        )

        parser = described_class.new(calendar, url: calendar.source)

        data = parser.download_calendar

        consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
        consumer.consume data
        consumer.validate_events
        consumer.events

        expected = "https://www.outsavvy.com/event/25977/ldn-queer-mart-lgbtqia-art-market"

        expect(consumer.events[0].publisher_url).to eq(expected)
      end
    end

    it "detects cancelled events" do
      VCR.use_cassette(:outsavvy_cancelled_event) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: "https://www.outsavvy.com/organiser/a-whole-orange"
        )

        parser = described_class.new(calendar, url: calendar.source)

        data = parser.download_calendar

        consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
        consumer.consume data
        consumer.events

        expect(consumer.events[18].not_cancelled?).to be(false)
      end
    end

    context "with an event page" do
      let(:calendar) { build(:calendar, strategy: :event, source: "https://www.outsavvy.com/organiser/test") }
      let(:parser) { described_class.new(calendar, url: calendar.source) }
      let(:ld_json) do
        { "@context": "http://schema.org", "@type": "MusicEvent", name: "Gig", startDate: 1.year.from_now.iso8601,
          url: "https://www.outsavvy.com/event/1/gig", description: "HeadlinerParagraph one" }.to_json
      end

      def imported_description(body)
        allow(parser).to receive(:extract_event_urls).and_return(["https://www.outsavvy.com/event/1/gig"])
        allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(
          %(<html><head><script type="application/ld+json">#{ld_json}</script></head><body>#{body}</body></html>)
        )

        parser.import_events_from(parser.download_calendar).first.attributes[:description]
      end

      it "reads the description from the page, keeping its paragraphs" do
        description = imported_description(<<~HTML)
          <div class="event-description"><h3>Track your loved events</h3></div>
          <div id="description"><div class="event-description">
            <span><p><strong>Headliner</strong></p><p>&nbsp;</p><p>Paragraph one</p><ul><li>Step-free</li></ul></span>
          </div></div>
        HTML

        expect(description).to eq("**Headliner**\n\nParagraph one\n\n* Step-free")
      end

      it "falls back to the ld+json description when the page has none" do
        expect(imported_description("<div class=\"event-description\">Promo</div>")).to eq("HeadlinerParagraph one")
      end
    end
  end
end
