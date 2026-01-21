# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::WixEvent do
  subject(:wix_event) { described_class.new(event_data, base_url: "https://example.com") }

  let(:event_data) do
    {
      "id" => "event-abc-123",
      "title" => "Community Gathering",
      "description" => "Join us for a community gathering!",
      "slug" => "community-gathering-2026-01-17",
      "scheduling" => {
        "config" => {
          "startDate" => "2026-01-17T19:00:00.000Z",
          "endDate" => "2026-01-17T23:00:00.000Z",
          "timeZoneId" => "Europe/London",
          "scheduleTbd" => false
        }
      },
      "location" => {
        "name" => "Community Hall",
        "address" => "123 Main Street, Manchester M1 1AA, UK",
        "fullAddress" => {
          "formattedAddress" => "123 Main Street, Manchester M1 1AA, UK",
          "postalCode" => "M1 1AA",
          "city" => "Manchester"
        }
      }
    }
  end

  describe "#uid" do
    it "returns the event ID" do
      expect(wix_event.uid).to eq("event-abc-123")
    end
  end

  describe "#summary" do
    it "returns the event title" do
      expect(wix_event.summary).to eq("Community Gathering")
    end
  end

  describe "#description" do
    it "returns the event description" do
      expect(wix_event.description).to eq("Join us for a community gathering!")
    end

    it "returns empty string when no description" do
      data = event_data.except("description")
      event = described_class.new(data)
      expect(event.description).to eq("")
    end
  end

  describe "#dtstart" do
    it "parses the start date correctly" do
      expect(wix_event.dtstart).to eq(DateTime.parse("2026-01-17T19:00:00.000Z"))
    end

    it "returns nil for missing start date" do
      data = event_data.deep_dup
      data["scheduling"]["config"].delete("startDate")
      event = described_class.new(data)
      expect(event.dtstart).to be_nil
    end
  end

  describe "#dtend" do
    it "parses the end date correctly" do
      expect(wix_event.dtend).to eq(DateTime.parse("2026-01-17T23:00:00.000Z"))
    end
  end

  describe "#location" do
    it "returns formatted address when available" do
      expect(wix_event.location).to eq("123 Main Street, Manchester M1 1AA, UK")
    end

    it "falls back to name and address when no formatted address" do
      data = event_data.deep_dup
      data["location"].delete("fullAddress")
      event = described_class.new(data)
      expect(event.location).to eq("Community Hall, 123 Main Street, Manchester M1 1AA, UK")
    end

    it "returns nil when no location" do
      data = event_data.except("location")
      event = described_class.new(data)
      expect(event.location).to be_nil
    end
  end

  describe "#publisher_url" do
    it "constructs URL from base_url and slug" do
      expect(wix_event.publisher_url).to eq("https://example.com/event-details/community-gathering-2026-01-17")
    end

    it "returns nil when no base_url" do
      event = described_class.new(event_data)
      expect(event.publisher_url).to be_nil
    end

    it "returns nil when no slug" do
      data = event_data.except("slug")
      event = described_class.new(data, base_url: "https://example.com")
      expect(event.publisher_url).to be_nil
    end
  end

  describe "#occurrences_between" do
    it "returns single occurrence with start and end times" do
      occurrences = wix_event.occurrences_between(Time.zone.now, 1.year.from_now)

      expect(occurrences.length).to eq(1)
      expect(occurrences.first.start_time).to eq(wix_event.dtstart)
      expect(occurrences.first.end_time).to eq(wix_event.dtend)
    end
  end
end
