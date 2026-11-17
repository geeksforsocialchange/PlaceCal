# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Events::IcsEvent do
  subject(:ics_event) { described_class.new(ical_event, start_date, end_date) }

  let(:start_date) { DateTime.parse("2026-01-17T19:00:00Z") }
  let(:end_date) { DateTime.parse("2026-01-17T21:00:00Z") }
  let(:location) { nil }
  let(:event_url) { nil }
  let(:description) { "A test event description" }

  let(:custom_properties) { {} }

  let(:ical_event) do
    event = double("Icalendar::Event")
    allow(event).to receive_messages(
      uid: "test-event-123",
      summary: "Test Event",
      description:,
      location:,
      rrule: nil,
      last_modified: nil,
      url: event_url,
      custom_properties:
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

    context "when LOCATION is a ticket URL and there is no URL property" do
      let(:location) { " https://tickets.example.com/gig " }

      it "returns the LOCATION URL" do
        expect(ics_event.publisher_url).to eq("https://tickets.example.com/gig")
      end
    end

    context "when LOCATION is a ticket URL and there is a URL property" do
      let(:location) { "https://tickets.example.com/gig" }
      let(:event_url) { "https://example.com/events/my-event" }

      it "returns the URL property" do
        expect(ics_event.publisher_url).to eq("https://example.com/events/my-event")
      end
    end

    context "when LOCATION is a meeting link" do
      let(:location) { "https://zoom.us/j/123456789" }

      it "returns nil" do
        expect(ics_event.publisher_url).to be_nil
      end
    end
  end

  describe "#online_event_id" do
    # Calendar custom properties for online meetings
    {
      "x_google_conference" => "https://meet.google.com/abc-defg-hij",
      "x_microsoft_skypeteamsmeetingurl" => "https://teams.microsoft.com/l/meetup-join/abc123",
      "x_microsoft_onlinemeetingconflink" => "https://teams.microsoft.com/meet/abc123",
      "x_zoom_meeting_url" => "https://zoom.us/j/123456789"
    }.each do |property, url|
      context "when #{property} custom property is set" do
        let(:custom_properties) { { property => url } }

        it "treats it as a direct online event" do
          expect(ics_event.online_event_id).not_to be_nil
          online_address = OnlineAddress.find(ics_event.online_event_id)
          expect(online_address.url).to eq(url)
        end
      end
    end

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

    context "when a custom property is on an unlisted host" do
      let(:custom_properties) { { "x_google_conference" => "https://meet.example.org/room" } }

      it "treats it as a direct online event" do
        expect(OnlineAddress.find(ics_event.online_event_id).link_type).to eq("direct")
      end
    end

    # Ticket, info and social pages in LOCATION are the event's webpage, not a way to attend
    %w[
      https://example.com/meeting
      http://example.com/meeting
      https://www.ticketsource.co.uk/whats-on/gig
      https://tickets.example.com/gig?via=zoom.us
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
    ].each do |url|
      context "when location is #{url}" do
        let(:location) { url }

        it "does not treat it as an online event" do
          expect(ics_event.online_event_id).to be_nil
        end
      end
    end

    # Meeting platforms in LOCATION are how to attend
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

    context "when an in-person event has a ticket URL in LOCATION" do
      let(:location) { "https://tickets.example.com/gig" }

      it "gives no online address" do
        expect(ics_event.online_event_id).to be_nil
      end
    end

    %w[
      https://www.facebook.com/ourgroup
      https://www.instagram.com/ourgroup
      https://www.linkedin.com/company/ourgroup
      https://www.youtube.com/@ourgroup
    ].each do |url|
      context "when the description links to #{url}" do
        let(:description) { "Come along to the hall! Follow us at #{url}" }

        it "gives no online address" do
          expect(ics_event.online_event_id).to be_nil
        end
      end
    end

    context "when the description has a Zoom link" do
      let(:description) { "Join us at https://us02web.zoom.us/j/123456789 or follow https://www.facebook.com/ourgroup" }

      it "treats it as a direct online event" do
        online_address = OnlineAddress.find(ics_event.online_event_id)
        expect(online_address.url).to eq("https://us02web.zoom.us/j/123456789")
        expect(online_address.link_type).to eq("direct")
      end
    end
  end
end
