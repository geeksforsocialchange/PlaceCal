# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::IcsEvent do
  subject(:ics_event) { described_class.new(ical_event, start_date, end_date) }

  let(:start_date) { DateTime.parse("2026-01-17T19:00:00Z") }
  let(:end_date) { DateTime.parse("2026-01-17T21:00:00Z") }
  let(:location) { nil }
  let(:event_url) { nil }

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
      it "returns nil" do
        expect(ics_event.publisher_url).to be_nil
      end
    end
  end

  describe "#online_event_id" do
    # Things that should NOT be detected as online
    [
      ["event URL property (webpage link)", { event_url: "https://example.com/events/my-event" }],
      ["plain place name", { location: "Community Hall, Manchester" }],
      ["single word location", { location: "Norfolk" }],
      ["'Online' text (no actual link)", { location: "Online" }],
      ["'Zoom' text (no actual link)", { location: "Zoom" }],
      ["blank location", { location: "" }],
      ["nil location", { location: nil }]
    ].each do |description, attrs|
      context "when #{description}" do
        let(:location) { attrs[:location] }
        let(:event_url) { attrs[:event_url] }

        it "does not treat it as an online event" do
          expect(ics_event.online_event_id).to be_nil
        end
      end
    end

    # Generic URLs should be indirect
    %w[
      https://example.com/meeting
      http://example.com/meeting
    ].each do |url|
      context "when location is generic URL #{url}" do
        let(:location) { url }

        it "treats it as an indirect online event" do
          expect(ics_event.online_event_id).not_to be_nil
          online_address = OnlineAddress.find(ics_event.online_event_id)
          expect(online_address.url).to eq(url)
          expect(online_address.link_type).to eq("indirect")
        end
      end
    end

    # Known platforms should be direct
    # Video conferencing, live streaming, and webinar platforms
    %w[
      https://us04web.zoom.us/j/123456789
      https://meet.google.com/abc-defg-hij
      https://meet.jit.si/MyMeetingRoom
      https://teams.microsoft.com/l/meetup-join/abc123
      https://meet.webex.com/meet/abc123
      https://gotomeet.me/abc123
      https://www.gotomeeting.com/join/abc123
      https://discord.gg/abc123
      https://discord.com/invite/abc123
      https://www.youtube.com/watch?v=dQw4w9WgXcQ
      https://youtu.be/dQw4w9WgXcQ
      https://www.twitch.tv/somechannel
      https://vimeo.com/123456789
      https://www.facebook.com/events/123456789
      https://fb.watch/abc123
      https://www.instagram.com/somechannel/live
      https://www.linkedin.com/video/live/urn:li:ugcPost:123456789
      https://www.crowdcast.io/e/my-event
      https://streamyard.com/watch/abc123
      https://hopin.com/events/my-event
    ].each do |url|
      context "when location is #{url}" do
        let(:location) { url }

        it "treats it as a direct online event" do
          expect(ics_event.online_event_id).not_to be_nil
          online_address = OnlineAddress.find(ics_event.online_event_id)
          expect(online_address.url).to eq(url)
          expect(online_address.link_type).to eq("direct")
        end
      end
    end
  end
end
