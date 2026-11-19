# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarSourceResolver do
  describe "Eventbrite event links" do
    let(:event_api) { "https://www.eventbriteapi.com/v3/events/918839984127/" }

    before { allow(ENV).to receive(:fetch).and_call_original }

    context "with an API token" do
      before do
        allow(ENV).to receive(:fetch).with("EVENTBRITE_TOKEN", nil).and_return("test-token")
        stub_request(:get, event_api).with(headers: { "Authorization" => "Bearer test-token" })
                                     .to_return(status: 200, body: { id: "918839984127", organizer_id: "85889707613" }.to_json)
      end

      it "swaps an event link for its organiser's page on the same site", :aggregate_failures do
        result = described_class.call("https://www.eventbrite.co.uk/e/918839984127?aff=oddtdtcreator")

        expect(result.kind).to eq("eventbrite")
        expect(result.source).to eq("https://www.eventbrite.co.uk/o/85889707613")
        expect(result.source).to match(CalendarImporter::Parsers::Eventbrite.allowlist_pattern)
      end

      it "reads the event id from the end of a named event link" do
        result = described_class.call("https://www.eventbrite.com/e/transpace-social-group-tickets-918839984127")

        expect(result.source).to eq("https://www.eventbrite.com/o/85889707613")
      end

      it "gives up when the event doesn't exist" do
        stub_request(:get, event_api).to_return(status: 404, body: { error: "NOT_FOUND" }.to_json)

        expect(described_class.call("https://www.eventbrite.co.uk/e/918839984127")).to be_nil
      end

      it "gives up when Eventbrite times out" do
        stub_request(:get, event_api).to_timeout

        expect(described_class.call("https://www.eventbrite.co.uk/e/918839984127")).to be_nil
      end

      it "leaves Eventbrite sites the importer can't read alone" do
        expect(described_class.call("https://www.eventbrite.ca/e/918839984127")).to be_nil
        expect(a_request(:any, /eventbrite/)).not_to have_been_made
      end
    end

    it "asks nothing without an API token" do
      allow(ENV).to receive(:fetch).with("EVENTBRITE_TOKEN", nil).and_return(nil)

      expect(described_class.call("https://www.eventbrite.co.uk/e/918839984127")).to be_nil
      expect(a_request(:any, /eventbrite/)).not_to have_been_made
    end
  end

  describe "Luma pages" do
    let(:feed) { "https://api.lu.ma/ics/get?entity=calendar&id=cal-8tfFZUVfInFAcNa" }

    def stub_luma(slug, body, status: 200)
      stub_request(:get, "https://api.lu.ma/url?url=#{slug}").to_return(status:, body: body.to_json)
    end

    it "swaps a calendar page for its iCal feed", :aggregate_failures do
      stub_luma("london-pattern-club", { kind: "calendar", data: { calendar: { api_id: "cal-8tfFZUVfInFAcNa", is_personal: false } } })

      %w[https://lu.ma/london-pattern-club https://luma.com/london-pattern-club/].each do |url|
        result = described_class.call(url)
        expect(result.kind).to eq("luma")
        expect(result.source).to eq(feed)
      end
    end

    it "swaps an event page for the feed of the calendar it belongs to" do
      stub_luma("b9cippxg", { kind: "event", data: { event: { api_id: "evt-1" }, calendar: { api_id: "cal-8tfFZUVfInFAcNa", is_personal: false } } })

      expect(described_class.call("https://luma.com/b9cippxg?tk=abc").source).to eq(feed)
    end

    it "leaves an event hosted on a person's own calendar alone" do
      stub_luma("vy0r1xpo", { kind: "event", data: { calendar: { api_id: "cal-AZgCl49l5YIUAzF", is_personal: true } } })

      expect(described_class.call("https://luma.com/vy0r1xpo")).to be_nil
    end

    it "leaves other kinds of Luma page alone" do
      stub_luma("london", { kind: "discover-place", data: { place: { api_id: "discplace-QCcNk3HXowOR97j" } } })

      expect(described_class.call("https://luma.com/london")).to be_nil
    end

    it "gives up on a page Luma doesn't know" do
      stub_luma("nothing-here", { message: "Sorry, we could not find what you were looking for." }, status: 404)

      expect(described_class.call("https://lu.ma/nothing-here")).to be_nil
    end

    it "gives up when Luma's answer can't be read" do
      stub_request(:get, "https://api.lu.ma/url?url=london-pattern-club").to_return(status: 200, body: "<html>")

      expect(described_class.call("https://lu.ma/london-pattern-club")).to be_nil
    end

    it "gives up when Luma times out" do
      stub_request(:get, "https://api.lu.ma/url?url=london-pattern-club").to_timeout

      expect(described_class.call("https://lu.ma/london-pattern-club")).to be_nil
    end

    it "leaves Luma's own feed and longer paths alone" do
      expect(described_class.call(feed)).to be_nil
      expect(described_class.call("https://luma.com/calendar/manage/cal-8tfFZUVfInFAcNa")).to be_nil
      expect(a_request(:any, /lu\.ma|luma\.com/)).not_to have_been_made
    end
  end

  it "leaves other links alone without asking anyone" do
    expect(described_class.call("https://example.com/events.ics")).to be_nil
    expect(described_class.call(nil)).to be_nil
    expect(a_request(:any, /.*/)).not_to have_been_made
  end
end
