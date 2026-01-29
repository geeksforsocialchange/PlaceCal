# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::LinkedDataEvent do
  describe "#extract_location" do
    it "extracts full address with all components" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" },
        "location" => {
          "name" => "Test Venue",
          "address" => {
            "street_address" => "123 Main Street",
            "address_locality" => "London",
            "address_region" => "England",
            "postal_code" => "SE1 1AA"
          }
        }
      }

      event = described_class.new(data)

      expect(event.location).to eq("123 Main Street, London, England, SE1 1AA")
    end

    it "extracts postcode from full address" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" },
        "location" => {
          "name" => "Test Venue",
          "address" => {
            "street_address" => "123 Main Street",
            "address_locality" => "London",
            "postal_code" => "SE1 1AA"
          }
        }
      }

      event = described_class.new(data)

      expect(event.postcode).to eq("SE1 1AA")
    end

    it "handles missing address components gracefully" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" },
        "location" => {
          "name" => "Test Venue",
          "address" => {
            "street_address" => "123 Main Street",
            "postal_code" => "SE1 1AA"
          }
        }
      }

      event = described_class.new(data)

      expect(event.location).to eq("123 Main Street, SE1 1AA")
    end

    it "falls back to venue name when no address hash" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" },
        "location" => {
          "name" => "Test Venue"
        }
      }

      event = described_class.new(data)

      expect(event.location).to eq("Test Venue")
    end

    it "returns nil when no location" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" }
      }

      event = described_class.new(data)

      expect(event.location).to be_nil
    end
  end

  describe "#parse_timestamp" do
    it "parses standard ISO 8601 timestamps" do
      data = {
        "url" => "https://example.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2026-06-01T11:00:00+01:00" }
      }

      event = described_class.new(data)

      expect(event.start_time).to eq(DateTime.new(2026, 6, 1, 11, 0, 0, "+01:00"))
    end
  end
end
