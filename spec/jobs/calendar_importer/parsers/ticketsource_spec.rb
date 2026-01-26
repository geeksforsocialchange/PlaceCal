# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Ticketsource do
  describe "constants" do
    it "has the correct NAME" do
      expect(described_class::NAME).to eq("TicketSource")
    end

    it "has the correct KEY" do
      expect(described_class::KEY).to eq("ticketsource")
    end

    it "has the correct DOMAINS" do
      expect(described_class::DOMAINS).to eq(%w[www.ticketsource.co.uk ticketsource.co.uk])
    end
  end

  describe ".allowlist_pattern" do
    it "matches www.ticketsource.co.uk venue pages" do
      expect(described_class.allowlist_pattern).to match("https://www.ticketsource.co.uk/fairfield-house")
    end

    it "matches ticketsource.co.uk venue pages without www" do
      expect(described_class.allowlist_pattern).to match("https://ticketsource.co.uk/some-venue")
    end

    it "matches venue pages with trailing slash" do
      expect(described_class.allowlist_pattern).to match("https://www.ticketsource.co.uk/fairfield-house/")
    end

    it "does not match event subpages" do
      expect(described_class.allowlist_pattern).not_to match("https://www.ticketsource.co.uk/fairfield-house/event/e-xxxxx")
    end

    it "does not match non-ticketsource URLs" do
      expect(described_class.allowlist_pattern).not_to match("https://www.example.com/fairfield-house")
    end
  end

  describe ".handles_url?" do
    it "returns truthy for valid TicketSource venue URLs" do
      calendar = build(:calendar, source: "https://www.ticketsource.co.uk/fairfield-house")
      expect(described_class).to be_handles_url(calendar)
    end

    it "returns falsy for non-TicketSource URLs" do
      calendar = build(:calendar, source: "https://www.example.com/events")
      expect(described_class).not_to be_handles_url(calendar)
    end
  end

  describe "#download_calendar" do
    let(:url) { "https://www.ticketsource.co.uk/fairfield-house" }
    let(:calendar) { build(:calendar, source: url, last_checksum: nil) }

    it "downloads and extracts event data from TicketSource venue page" do
      VCR.use_cassette("ticketsource_fairfield_house", allow_playback_repeats: true) do
        parser = described_class.new(calendar)
        data = parser.download_calendar

        expect(data).to be_an(Array)
        expect(data).not_to be_empty

        first_event = data.first
        expect(first_event["name"]).to be_present
        expect(first_event["url"]).to include("ticketsource.co.uk")
        expect(first_event.dig("start_date", "@value")).to be_present
      end
    end
  end

  describe "#import_events_from" do
    let(:url) { "https://www.ticketsource.co.uk/fairfield-house" }
    let(:calendar) { build(:calendar, source: url, last_checksum: nil) }

    it "converts raw data to LinkedDataEvent objects" do
      VCR.use_cassette("ticketsource_fairfield_house", allow_playback_repeats: true) do
        parser = described_class.new(calendar)
        data = parser.download_calendar
        events = parser.import_events_from(data)

        expect(events).to be_an(Array)
        expect(events).not_to be_empty
        expect(events.first).to be_a(CalendarImporter::Events::LinkedDataEvent)
      end
    end

    it "creates valid events with required fields" do
      VCR.use_cassette("ticketsource_fairfield_house", allow_playback_repeats: true) do
        parser = described_class.new(calendar)
        data = parser.download_calendar
        events = parser.import_events_from(data)

        events.each do |event|
          expect(event.valid?).to be(true), "Event should be valid: #{event.summary}"
          expect(event.uid).to be_present
          expect(event.summary).to be_present
          expect(event.start_time).to be_present
        end
      end
    end

    it "extracts location information" do
      VCR.use_cassette("ticketsource_fairfield_house", allow_playback_repeats: true) do
        parser = described_class.new(calendar)
        data = parser.download_calendar
        events = parser.import_events_from(data)

        event_with_location = events.find { |e| e.location.present? }
        expect(event_with_location).to be_present
        expect(event_with_location.location).to include("BA1")
      end
    end

    it "returns empty array for nil input" do
      parser = described_class.new(calendar)
      expect(parser.import_events_from(nil)).to eq([])
    end

    it "returns empty array for non-array input" do
      parser = described_class.new(calendar)
      expect(parser.import_events_from("invalid")).to eq([])
    end
  end
end
