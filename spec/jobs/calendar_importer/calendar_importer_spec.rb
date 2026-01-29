# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporter do
  describe "#parser" do
    context "with webcal calendars" do
      let(:url) { "webcal://p24-calendars.icloud.com/published/2/WvhkIr4F3oBQrToPU-lkO6WwDTpzNTpENs-Qtbo48FhhrAfDp3gkIal2XPd5eUVO0LLERrehetRzj43c6zvbotf9_DNI6heKXBejvAkz8JQ" }

      it "imports webcal calendars" do
        VCR.use_cassette("Yellowbird_Webcal", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Yellowbird", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(2)
          expect(events.first.summary).to eq("Age Friendly Community Soup")
          expect(events.last.summary).to eq("YellowBird Age Friendly Drop-in")
        end
      end
    end

    context "with google calendars" do
      let(:url) { "https://calendar.google.com/calendar/ical/alliscalm.net_u2ktkhtig0b7u9bd9j8re3af2k%40group.calendar.google.com/public/basic.ics" }

      it "imports google calendars" do
        VCR.use_cassette("Placecal_Hulme_Moss_Side_Google_Cal", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Placecal Hulme & Moss Size", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(139)
          expect(events.first.summary).to eq("Dementia Friends Walk and Talk Group")
          expect(events.first.description).to eq("Session run by Together Dementia Support call Sally on: 0161 2839970")
        end
      end
    end

    context "with outlook365.com calendars" do
      let(:url) { "https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics" }

      it "imports outlook365.com calendars" do
        VCR.use_cassette("Zion_Centre_Guide", allow_playback_repeats: true) do
          calendar = create(:calendar, source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(24)
          expect(events.first.summary).to eq("Hypnotherapy")
          expect(events.last.summary).to eq("Donna - Ashtanga Yoga")
        end
      end
    end

    context "with live.com calendars" do
      let(:url) { "https://outlook.live.com/owa/calendar/1c816fe0-358f-4712-9b0f-0265edacde57/8306ff62-3b76-4ad5-8dbe-db435bfea444/cid-536CE5C17F8CF3C2/calendar.ics" }

      it "imports live.com calendars" do
        VCR.use_cassette("ACCG", allow_playback_repeats: true) do
          calendar = create(:calendar, source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(0)
        end
      end
    end

    context "with manchester uni calendars" do
      let(:url) { "http://events.manchester.ac.uk/f3vf/calendar/tag:martin_harris_centre/view:list/p:q_details/calml.xml" }

      it "imports manchester uni calendars" do
        VCR.use_cassette("Martin_Harris_Centre", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Martin Harris Centre", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(3)
          expect(events.first.summary).to eq("Technical tours of the Martin Harris Centre for Music and Drama")
          expect(events.last.summary).to eq("KIDNAP@20: The Art of Incarceration")
        end
      end
    end

    context "with ticketsolve calendars" do
      let(:url) { "https://z-arts.ticketsolve.com/shows.xml" }

      it "imports ticketsolve calendars" do
        VCR.use_cassette("Z-Arts_Calendar", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Z-Arts", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(38)
          expect(events.first.summary).to eq("Inuk")
          expect(events.last.summary).to eq("ZYP: Unusual Theatre in Unusual Spaces")
        end
      end
    end

    context "with teamup calendars" do
      let(:url) { "https://ics.teamup.com/feed/ksq8ayp7mw5mhb193x/5941140.ics" }

      it "imports teamup calendars" do
        VCR.use_cassette("Teamup_com_calendar", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Teamup.com", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(25)
          expect(events.first.summary).to eq("Mudeford Lifeboat Fun Day")
          expect(events.last.summary).to eq("BEETLE DRIVE")
        end
      end
    end

    context "with eventbrite calendars" do
      let(:url) { "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483" }

      it "imports eventbrite calendars" do
        VCR.use_cassette("Eventbrite_calendar", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "Eventbrite - Queer Lit & Social Refuge", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(73)
          expect(events.first.summary).to eq("Do You Believe in Life After Loss – Andrew Flewitt in Conversation.")
          expect(events.last.summary).to eq("Write That Novel: A writers workshop")
        end
      end
    end

    context "with squarespace calendars" do
      let(:url) { "https://robin-cunningham-dh7d.squarespace.com/our-events/" }

      it "imports squarespace calendars" do
        VCR.use_cassette("Squarespace_calendar", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "VFD - squarespace", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(16)
          expect(events.first.summary).to eq("crazinsT artisT: Before Dawn")
          expect(events.last.summary).to eq("The Matrix: Dance Dance Revolutions")
        end
      end
    end

    context "with DiceFM (ld+json) calendars" do
      let(:url) { "https://dice.fm/venue/folklore-2or7" }

      it "imports DiceFM events from ld+json source" do
        VCR.use_cassette("dice_fm_events", allow_playback_repeats: true) do
          calendar = create(:calendar, name: "DiceFM", source: url)

          parser_class = described_class.new(calendar).parser
          output = parser_class.new(calendar).calendar_to_events
          events = output.events

          expect(events.count).to eq(15)
          expect(events.first.summary).to eq("Kai Bosch")
          expect(events.last.summary).to eq("Molly Payton")
        end
      end
    end

    context "with ticketsource calendars" do
      let(:url) { "https://www.ticketsource.co.uk/fairfield-house" }

      let(:events_response) do
        {
          "data" => [
            {
              "id" => "evt_1",
              "type" => "event",
              "attributes" => {
                "name" => "Guided Tour",
                "description" => "A guided tour",
                "reference" => "guided-tour",
                "archived" => false,
                "public" => true
              }
            }
          ],
          "links" => { "next" => nil }
        }.to_json
      end

      let(:dates_response) do
        {
          "data" => [
            {
              "id" => "date_1",
              "attributes" => {
                "start" => "2026-03-15T10:00:00+00:00",
                "end" => "2026-03-15T12:00:00+00:00",
                "cancelled" => false
              }
            }
          ]
        }.to_json
      end

      let(:venues_response) do
        {
          "data" => [
            {
              "id" => "ven_1",
              "attributes" => {
                "name" => "Fairfield House",
                "address" => { "line_1" => "Bath", "postcode" => "BA1 5AH" }
              }
            }
          ]
        }.to_json
      end

      it "imports ticketsource calendars" do
        stub_request(:get, %r{api\.ticketsource\.io/events\?})
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, %r{api\.ticketsource\.io/events/evt_1/dates})
          .to_return(status: 200, body: dates_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, %r{api\.ticketsource\.io/events/evt_1/venues})
          .to_return(status: 200, body: venues_response, headers: { "Content-Type" => "application/json" })

        calendar = create(:calendar, name: "Fairfield House", source: url,
                                     importer_mode: "ticketsource", api_token: "test_key")

        parser_class = described_class.new(calendar).parser
        output = parser_class.new(calendar).calendar_to_events
        events = output.events

        expect(events.count).to eq(1)
        expect(events.first.summary).to eq("Guided Tour")
      end
    end
  end

  describe "checksum handling" do
    let(:url) { "https://z-arts.ticketsolve.com/shows.xml" }
    let(:checksum) { "d1a94a9869af91d0548a1faf0ded91d7" }

    it "does not import if checksum is the same" do
      VCR.use_cassette("Z-Arts_Calendar", allow_playback_repeats: true) do
        calendar = create(:calendar, name: "Z-Arts", last_checksum: checksum, source: url)

        parser_class = described_class.new(calendar).parser
        output = parser_class.new(calendar).calendar_to_events

        expect(output.events).to be_empty
      end
    end
  end

  describe "auto detection" do
    it "can pick up ld+json source" do
      VCR.use_cassette("heart_of_torbay") do
        calendar = create(:calendar, name: "Heart of Torbay", source: "https://www.heartoftorbaycic.com/events", importer_mode: "auto")

        parser_class = described_class.new(calendar).parser
        expect(parser_class::KEY).to eq("ld-json")
      end
    end

    it "raises error for unhandled calendar sources" do
      VCR.use_cassette("gfsc_studio") do
        calendar = build(:calendar, name: "GFSC Studio", source: "https://gfsc.studio", importer_mode: "auto")

        expect do
          described_class.new(calendar).parser
        end.to raise_error(CalendarImporter::Exceptions::UnsupportedFeed)
      end
    end
  end

  describe "bad URL handling" do
    it "raises error for empty URL" do
      calendar = build(:calendar, source: "")

      expect do
        described_class.new(calendar)
      end.to raise_error(CalendarImporter::Exceptions::UnsupportedFeed, /missing/)
    end

    it "raises error for invalid URL format" do
      calendar = build(:calendar, source: "hts://example,com")

      expect do
        described_class.new(calendar)
      end.to raise_error(CalendarImporter::Exceptions::UnsupportedFeed, /not a valid URL/)
    end
  end
end
