# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::IcsEvent do
  subject(:ics_event) { described_class.new(ical_event, start_date, end_date) }

  let(:start_date) { DateTime.parse("2026-01-17T19:00:00Z") }
  let(:end_date) { DateTime.parse("2026-01-17T21:00:00Z") }
  let(:location) { nil }
  let(:event_url) { nil }

  # Create a minimal mock iCal event
  let(:ical_event) do
    event = double("Icalendar::Event")
    allow(event).to receive_messages(
      uid: "test-event-123",
      summary: "Test Event",
      description: "A test event description",
      location: location,
      rrule: nil,
      last_modified: nil,
      url: event_url,
      custom_properties: {}
    )
    event
  end

  describe "#publisher_url" do
    context "when event has a URL property" do
      let(:event_url) { "https://example.com/events/my-event" }

      it "returns the URL as publisher_url" do
        expect(ics_event.publisher_url).to eq("https://example.com/events/my-event")
      end
    end

    context "when event URL is an array" do
      let(:event_url) { ["https://example.com/events/my-event"] }

      it "returns the first URL" do
        expect(ics_event.publisher_url).to eq("https://example.com/events/my-event")
      end
    end

    context "when event has no URL" do
      let(:event_url) { nil }

      it "returns nil" do
        expect(ics_event.publisher_url).to be_nil
      end
    end
  end

  describe "#online_event_id" do
    context "when event has a URL property (webpage link)" do
      let(:event_url) { "https://example.com/events/my-event" }

      it "does NOT treat it as an online event (URL is for event info, not online meeting)" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is a plain place name" do
      let(:location) { "Community Hall, Manchester" }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is just a single word" do
      let(:location) { "Norfolk" }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is 'Online'" do
      let(:location) { "Online" }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is 'Zoom'" do
      let(:location) { "Zoom" }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is a valid https URL" do
      let(:location) { "https://example.com/meeting" }

      it "treats it as an online event" do
        expect(ics_event.online_event_id).not_to be_nil
        expect(OnlineAddress.find(ics_event.online_event_id).url).to eq("https://example.com/meeting")
      end
    end

    context "when location is a valid http URL" do
      let(:location) { "http://example.com/meeting" }

      it "treats it as an online event" do
        expect(ics_event.online_event_id).not_to be_nil
        expect(OnlineAddress.find(ics_event.online_event_id).url).to eq("http://example.com/meeting")
      end
    end

    context "when location is a Zoom meeting link" do
      let(:location) { "https://us04web.zoom.us/j/123456789" }

      it "treats it as a direct online event" do
        expect(ics_event.online_event_id).not_to be_nil
        online_address = OnlineAddress.find(ics_event.online_event_id)
        expect(online_address.url).to eq("https://us04web.zoom.us/j/123456789")
        expect(online_address.link_type).to eq("direct")
      end
    end

    context "when location is blank" do
      let(:location) { "" }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    context "when location is nil" do
      let(:location) { nil }

      it "does not treat it as an online event" do
        expect(ics_event.online_event_id).to be_nil
      end
    end
  end
end
