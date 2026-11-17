# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::SquarespaceEvent do
  let(:feed) { JSON.parse(file_fixture("squarespace_events_with_locations.json").read) }

  def event_with_id(id)
    described_class.new(feed["upcoming"].find { |event| event["id"] == id })
  end

  describe "#location" do
    it "joins the venue title and address lines, leaving out the country" do
      event = event_with_id("5f1e00000000000000000001")

      expect(event.location).to eq("Oldtown Community Hall, 10 Heritage Lane, Millbrook, ZZMB 2OT")
      expect(event.postcode).to eq("ZZMB 2OT")
    end

    it "returns the venue without a postcode when the address lines have none" do
      event = event_with_id("5f1e00000000000000000002")

      expect(event.location).to eq("The Reading Room, 4 Mill Lane, Millbrook")
      expect(event.postcode).to be_blank
    end

    it "returns nil when the address fields are blank" do
      event = event_with_id("5f1e00000000000000000003")

      expect(event.location).to be_nil
      expect(event.location?).to be false
    end

    it "skips blank and whitespace-only parts" do
      data = feed["upcoming"].first
      data["location"].merge!("addressTitle" => " ", "addressLine1" => "")

      expect(described_class.new(data).location).to eq("Millbrook, ZZMB 2OT")
    end

    it "decodes HTML entities and drops a title that repeats the street line" do
      data = feed["upcoming"].first
      data["location"].merge!("addressTitle" => "St Mary&#39;s Church", "addressLine1" => "St Mary&#39;s church")

      expect(described_class.new(data).location).to eq("St Mary's Church, Millbrook, ZZMB 2OT")
    end

    it "returns nil when the event has no location object" do
      data = feed["upcoming"].first.except("location")

      expect(described_class.new(data).location).to be_nil
    end
  end
end
