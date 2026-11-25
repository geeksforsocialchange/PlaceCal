# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::EventbriteEvent do
  subject(:event) { described_class.new(payload) }

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

  context "when the event is online" do
    let(:payload) { base_payload.merge("online_event" => true) }

    it "links to the Eventbrite page as an indirect online address" do
      address = OnlineAddress.find(event.online_event_id)

      expect(address).to have_attributes(url: "https://www.eventbrite.co.uk/e/123", link_type: "indirect")
    end
  end

  context "when the event is free" do
    let(:payload) { base_payload.merge("is_free" => true) }

    it "gives a price of 0" do
      expect(event.price_from).to eq(0)
    end
  end

  context "when the event has no description" do
    let(:payload) { base_payload.except("description") }

    it "gives no description and still builds its attributes" do
      expect(event.description).to be_nil
      expect(event.attributes).to include(summary: "Queer Lit Social", description: "")
    end
  end

  context "when the event has no name" do
    let(:payload) { base_payload.except("name") }

    it "gives a blank title, which the event's validation then rejects" do
      expect(event.summary).to be_nil
      expect(event.attributes[:summary]).to eq("")
    end
  end
end
