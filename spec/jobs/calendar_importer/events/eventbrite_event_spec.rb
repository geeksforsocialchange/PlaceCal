# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::EventbriteEvent do
  subject(:event) { described_class.new(sdk_event) }

  # Mirror production: the parser hands us SDK attribute objects, whose `[]`
  # raises NoMethodError for keys that are absent from the payload.
  let(:sdk_event) { EventbriteSDK::Resource::Attributes.new(payload) }

  let(:base_payload) do
    {
      "id" => "123",
      "name" => { "text" => "Queer Lit Social" },
      "description" => { "html" => "<p>Books</p>" },
      "url" => "https://www.eventbrite.co.uk/e/123",
      "start" => { "utc" => "2026-10-01T18:00:00Z" },
      "end" => { "utc" => "2026-10-01T20:00:00Z" },
      "online_event" => false
    }
  end

  context "when the venue expansion is present" do
    let(:payload) do
      base_payload.merge(
        "venue" => {
          "name" => "Refuge",
          "address" => {
            "address_1" => "Oxford Street",
            "address_2" => "",
            "city" => "Manchester",
            "region" => "",
            "postal_code" => "M60 7HA"
          }
        }
      )
    end

    it "builds the location from the venue" do
      expect(event.location).to eq("Refuge, Oxford Street, Manchester, M60 7HA")
    end
  end

  context "when Eventbrite omits the venue key entirely" do
    let(:payload) { base_payload }

    it "treats the event as having no place" do
      expect(event.place).to be_nil
    end

    it "returns no location instead of raising" do
      expect { event.location }.not_to raise_error
      expect(event.location).to be_nil
    end
  end

  context "when the venue key is present but null" do
    let(:payload) { base_payload.merge("venue" => nil) }

    it "returns no location" do
      expect(event.location).to be_nil
    end
  end
end
