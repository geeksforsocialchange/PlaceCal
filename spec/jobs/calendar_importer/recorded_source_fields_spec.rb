# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event fields read from each source's feed" do
  def imported(parser, cassette, url, **calendar_attributes)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      parser.new(build(:calendar, source: url, **calendar_attributes)).calendar_to_events.events
    end
  end

  describe "Ticketsolve" do
    let(:events) { imported(CalendarImporter::Parsers::Ticketsolve, "Z-Arts_Calendar", "https://z-arts.ticketsolve.com/shows.xml") }
    let(:inuk) { events.first }

    it "reads the venue each show is listed under as its location" do
      expect(events.map(&:location).tally).to eq("Manchester Communication Academy" => 1, "Z-arts" => 37)
    end

    it "reads the show's page as the webpage, and no longer adds it to the description" do
      expect(inuk.attributes[:publisher_url]).to eq("https://z-arts.ticketsolve.com/shows/873589467/events")
      expect(inuk.attributes[:description]).not_to include("Tickets:")
      expect(events.map { |event| event.attributes[:publisher_url] }).to all(start_with("https://z-arts.ticketsolve.com/shows/"))
    end

    it "reads the large image" do
      expect(inuk.attributes[:image_source_url])
        .to eq("https://dc40ra2rfm3rp.cloudfront.net/production_1/photos/125964535/Inukwebres_large.jpg")
      expect(events.map { |event| event.attributes[:image_source_url] }).to all(match(/_large\.(jpe?g|png)\z/i))
    end

    it "reads event_category as one source category, and stores none when it is blank" do
      categories = events.map { |event| event.attributes[:source_categories] }

      expect(inuk.attributes[:source_categories]).to eq(["Childrens Theatre"])
      expect(categories).to include(["Theatre, Dance & Music"], nil)
    end

    it "gives no location for a show outside a venue" do
      show = Nokogiri::XML("<show id='1'><name>A show</name><url>https://x.ticketsolve.com/shows/1</url></show>").at_css("show")

      expect(CalendarImporter::Events::TicketsolveEvent.new(show).location).to be_nil
    end
  end

  describe "Ticketsolve venue names under each location strategy" do
    let(:venue) { create(:partner) }
    let(:show) do
      Nokogiri::XML(<<~XML).at_css("show")
        <venue><name>Z-arts</name><shows><show id="1"><name>A show</name></show></shows></venue>
      XML
    end

    def resolve(strategy)
      calendar = build(:calendar, strategy:, place: venue)
      CalendarImporter::LocationResolver.new(calendar, CalendarImporter::Events::TicketsolveEvent.new(show)).resolve
    end

    it "places the event nowhere under the event strategy, since a name alone isn't an address" do
      expect(resolve("event")).to have_attributes(place: nil, address: nil, match: :none)
    end

    it "keeps the default venue under the event_override and place strategies" do
      expect(resolve("event_override")).to have_attributes(place: venue, match: :default_location)
      expect(resolve("place")).to have_attributes(place: venue, match: :default_location)
    end

    it "adds the venue name as a room under the room_number strategy" do
      expect(resolve("room_number")).to have_attributes(place: venue, match: :room)
      expect(resolve("room_number").address.street_address).to eq("Z-arts")
    end
  end

  describe "Wix" do
    let(:events) do
      VCR.use_cassette(:wix_events) do
        allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_call_original
        allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
          .with(a_string_including("/event-details/")).and_return("<html></html>")
        CalendarImporter::Parsers::Wix.new(build(:calendar, source: "https://www.socialrefuge.com/event-list", importer_mode: "wix"))
                                      .calendar_to_events.events
      end
    end

    it "reads the main image" do
      urls = events.map { |event| event.attributes[:image_source_url] }

      expect(urls.size).to eq(13)
      expect(urls).to all(start_with("https://static.wixstatic.com/media/"))
    end

    it "stores no categories from a feed whose category lists are empty" do
      expect(events.map { |event| event.attributes[:source_categories] }).to all(be_nil)
    end

    it "reads category names, given as Wix documents them, as objects" do
      event = CalendarImporter::Events::WixEvent.new(
        { "id" => "1", "title" => "A Wix event", "categories" => [{ "id" => "c1", "name" => "Workshops" }, { "id" => "c2", "name" => " " }] }
      )

      expect(event.attributes[:source_categories]).to eq(["Workshops"])
    end
  end

  describe "TicketSource, from its documented API (no recording exists)" do
    let(:record) do
      { "id" => "evt_1", "name" => "A show", "keywords" => "folk, dance,Folk", "category" => "Music", "genre" => "Folk",
        "images" => ["https://cdn.ticketsource.io/a.jpg", "https://cdn.ticketsource.io/b.jpg"] }
    end
    let(:event) do
      CalendarImporter::Events::TicketsourceEvent.new(record, { "id" => "d1", "start" => "2030-02-01T19:00:00Z" },
                                                      publisher_url: "https://www.ticketsource.co.uk/venue/a-show")
    end

    it "reads the first image" do
      expect(event.attributes[:image_source_url]).to eq("https://cdn.ticketsource.io/a.jpg")
    end

    it "reads keywords, category and genre as source categories" do
      expect(event.attributes[:source_categories]).to eq(%w[folk dance Music])
    end

    it "stores neither when the event has none" do
      bare = CalendarImporter::Events::TicketsourceEvent.new({ "id" => "evt_1" }, { "id" => "d1" }, publisher_url: nil)

      expect(bare.attributes).to include(image_source_url: nil, source_categories: nil)
    end
  end

  describe "Resident Advisor" do
    def events(cassette, url)
      imported(CalendarImporter::Parsers::ResidentAdvisor, cassette, url)
    end

    it "marks a club's event cancelled from its title, and takes the prefix off" do
      club_events = events(:ra_club, "https://ra.co/clubs/182584")
      cancelled = club_events.select { |event| event.attributes[:status] == "cancelled" }

      expect(cancelled.map { |event| event.attributes[:summary] }).to eq(["I See You presents: t e s t p r e s s"])
      expect(club_events.map(&:status).tally).to eq("cancelled" => 1, "scheduled" => 9)
    end

    it "takes off a prefix followed by a dash" do
      cancelled = events(:ra_promoter, "https://ra.co/promoters/73787").select { |event| event.status == "cancelled" }

      expect(cancelled.map { |event| event.attributes[:summary] }).to eq(["SEEING THE BLOSSOM - A PLAY"])
    end

    it "leaves other titles alone" do
      event = CalendarImporter::Events::ResidentAdvisor.new({ "title" => "Cancelled Plans [CANCELLED] party" })

      expect(event).to have_attributes(status: "scheduled", summary: "Cancelled Plans [CANCELLED] party")
    end
  end

  describe "LD+JSON" do
    it "keeps an address given as text, so dice.fm events have a street and postcode" do
      events = imported(CalendarImporter::Parsers::LdJson, :dice_fm_events, "https://dice.fm/venue/folklore-2or7")

      expect(events.map(&:location).uniq).to eq(["186 Hackney Rd, London E2 7QL, UK"])
      expect(events.map(&:postcode).uniq).to eq(["E2 7QL"])
    end

    it "keeps a generic site's text address" do
      events = imported(CalendarImporter::Parsers::LdJson, :heart_of_torbay_events, "https://www.heartoftorbaycic.com/events/")

      expect(events.map(&:location)).to eq(["TheBoathouse, Marine Drive, Paignton, TQ3 2NJ"])
      expect(events.map(&:postcode)).to eq(["TQ3 2NJ"])
    end

    it "falls back to the venue name when the text address is blank" do
      event = CalendarImporter::Events::LinkedDataEvent.new(
        { "url" => "https://example.com/1", "location" => { "name" => "The Hall", "address" => " " } }
      )

      expect(event.location).to eq("The Hall")
    end

    it "reads an older OutSavvy page's performer as the organiser when it names no organizer" do
      events = imported(CalendarImporter::Parsers::LdJson, :out_savvy_events, "https://www.outsavvy.com/organiser/sappho-events")

      expect(events.map { |event| event.attributes[:source_organiser] }).to eq(["Sappho Events"] * 4)
    end

    it "reads a performer only when there is no organizer and the performer is an organisation" do
      organisation = { "@type" => "http://schema.org/Organization", "name" => "Sappho Events" }
      band = { "@type" => "http://schema.org/MusicGroup", "name" => "A Band" }
      organiser = lambda do |extra|
        CalendarImporter::Events::LinkedDataEvent.new({ "url" => "https://example.com/1" }.merge(extra)).source_organiser
      end

      expect(organiser.call("http://schema.org/performer" => [band, organisation])).to eq("Sappho Events")
      expect(organiser.call("organiser" => { "name" => "Folk Club" }, "http://schema.org/performer" => organisation)).to eq("Folk Club")
      expect(organiser.call("http://schema.org/performer" => band)).to be_nil
      expect(organiser.call("http://schema.org/performer" => "")).to be_nil
    end
  end
end
