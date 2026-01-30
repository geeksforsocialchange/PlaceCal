# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::OutsavvyEvent do
  describe "#parse_timestamp" do
    it "fixes malformed OutSavvy timestamps with extra seconds component" do
      # OutSavvy produces timestamps like "2025-06-01T11:00:00:00+01:00"
      # Note the extra ":00" before the timezone offset
      data = {
        "url" => "https://www.outsavvy.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2025-06-01T11:00:00:00+01:00" },
        "end_date" => { "@value" => "2025-06-01T18:00:00:00+01:00" }
      }

      event = described_class.new(data)

      # Should correctly parse as 11:00 BST (British Summer Time, +01:00)
      expect(event.start_time).to eq(DateTime.new(2025, 6, 1, 11, 0, 0, "+01:00"))
      expect(event.end_time).to eq(DateTime.new(2025, 6, 1, 18, 0, 0, "+01:00"))
    end

    it "handles standard timestamps without modification" do
      data = {
        "url" => "https://www.outsavvy.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2025-06-01T11:00:00+01:00" }
      }

      event = described_class.new(data)

      expect(event.start_time).to eq(DateTime.new(2025, 6, 1, 11, 0, 0, "+01:00"))
    end

    it "preserves timezone offset from malformed timestamps" do
      # This test verifies that the timezone is NOT lost (the original bug)
      data = {
        "url" => "https://www.outsavvy.com/event/123",
        "name" => "Test Event",
        "start_date" => { "@value" => "2025-12-01T19:00:00:00+00:00" }
      }

      event = described_class.new(data)

      # Should be 19:00 UTC, not 19:00 in local time
      expect(event.start_time.zone).to eq("+00:00")
      expect(event.start_time.hour).to eq(19)
    end
  end
end
