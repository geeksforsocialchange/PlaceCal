# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::TicketsourceEvent do
  subject(:event) { described_class.new(sample_event) }

  let(:sample_event) do
    {
      "id" => "evt_123",
      "attributes" => {
        "name" => "Test Show",
        "description" => "A great show"
      },
      "date" => {
        "id" => "date_456",
        "attributes" => {
          "start" => "2026-03-15T19:30:00+00:00",
          "end" => "2026-03-15T22:00:00+00:00",
          "cancelled" => false
        }
      },
      "venue" => {
        "attributes" => {
          "name" => "Fairfield House",
          "address" => {
            "line_1" => "10 High Street",
            "line_2" => "",
            "line_3" => "Bath",
            "line_4" => "",
            "postcode" => "BA1 5AH"
          }
        }
      },
      "publisher_url" => "https://www.ticketsource.co.uk/fairfield-house/test-show"
    }
  end

  describe "#uid" do
    it "returns a composite of event and date IDs" do
      expect(event.uid).to eq("evt_123-date_456")
    end
  end

  describe "#summary" do
    it "returns the event name" do
      expect(event.summary).to eq("Test Show")
    end
  end

  describe "#description" do
    it "returns the event description" do
      expect(event.description).to eq("A great show")
    end

    it "returns empty string when description is nil" do
      sample_event["attributes"]["description"] = nil
      expect(event.description).to eq("")
    end
  end

  describe "#dtstart" do
    it "parses the start time" do
      expect(event.dtstart).to be_present
      expect(event.dtstart.year).to eq(2026)
      expect(event.dtstart.month).to eq(3)
      expect(event.dtstart.day).to eq(15)
      expect(event.dtstart.hour).to eq(19)
      expect(event.dtstart.min).to eq(30)
    end

    it "returns nil for blank start time" do
      sample_event["date"]["attributes"]["start"] = nil
      expect(event.dtstart).to be_nil
    end
  end

  describe "#dtend" do
    it "parses the end time" do
      expect(event.dtend).to be_present
      expect(event.dtend.hour).to eq(22)
    end
  end

  describe "#location" do
    it "joins venue name and address parts" do
      expect(event.location).to eq("Fairfield House, 10 High Street, Bath, BA1 5AH")
    end

    it "returns nil when venue is missing" do
      sample_event["venue"] = nil
      expect(event.location).to be_nil
    end

    it "skips blank address lines" do
      sample_event["venue"]["attributes"]["address"]["line_1"] = ""
      expect(event.location).to eq("Fairfield House, Bath, BA1 5AH")
    end
  end

  describe "#publisher_url" do
    it "returns the publisher URL" do
      expect(event.publisher_url).to eq("https://www.ticketsource.co.uk/fairfield-house/test-show")
    end
  end

  describe "#occurrences_between" do
    it "returns a single occurrence" do
      occurrences = event.occurrences_between(Time.zone.now, 1.year.from_now)
      expect(occurrences.length).to eq(1)
    end
  end
end
