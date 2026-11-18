# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Source categories and organiser" do
  def source_fields(events)
    events.map { |event| event.attributes.slice(:source_categories, :source_organiser) }
  end

  def imported(parser, cassette, url)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      source_fields(parser.new(build(:calendar, source: url)).calendar_to_events.events)
    end
  end

  def ics_event(vevent_lines)
    ics = <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//PlaceCal//Test//EN
      BEGIN:VEVENT
      UID:ics-1
      DTSTART:20300201T190000Z
      SUMMARY:An iCal event
      #{vevent_lines}
      END:VEVENT
      END:VCALENDAR
    ICS
    vevent = Icalendar::Calendar.parse(ics).first.events.first
    CalendarImporter::Events::IcsEvent.new(vevent, vevent.dtstart, vevent.dtend)
  end

  def linked_data_events(*nodes)
    graph = nodes.each_with_index.map do |node, index|
      { "@type" => "Event", "name" => "Event #{index}", "url" => "https://example.com/#{index}", "startDate" => "2030-02-01T19:00" }.merge(node)
    end
    html = %(<script type="application/ld+json">#{{ '@context' => 'https://schema.org', '@graph' => graph }.to_json}</script>)
    consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
    consumer.consume(CalendarImporter::Parsers::Base.parse_ld_json_document(Nokogiri::HTML(html)))
    consumer.events
  end

  describe "iCal" do
    it "reads CATEGORIES from a Teamup feed" do
      fields = imported(CalendarImporter::Parsers::Ics, "Teamup_com_calendar", "https://ics.teamup.com/feed/ksq8ayp7mw5mhb193x/5941140.ics")

      expect(fields).to be_present.and(all(eq(source_categories: ["Guild Events"], source_organiser: nil)))
    end

    it "reads CATEGORIES from a Teamup feed at an unknown address" do
      fields = imported(CalendarImporter::Parsers::Ics, "Uknown Teamup Feed",
                        "https://not-a-real-calendar-provider.com/feed/ksq8ayp7mw5mhb193x/5941140.ics")

      expect(fields).to be_present.and(all(eq(source_categories: ["Fundraising Crew Events"], source_organiser: nil)))
    end

    it "reads CATEGORIES from a generic feed, and stores none for an event without them" do
      fields = imported(CalendarImporter::Parsers::Ics, :generic_ical_feed, "https://www.birchcommunitycentre.co.uk/events.ics")

      expect(fields.pluck(:source_categories).tally).to eq(["Open"] => 29, ["Activities"] => 16, ["Private"] => 2, nil => 3)
    end

    it "reads every value from one or several CATEGORIES lines, trimmed, without blanks or repeats in another case" do
      event = ics_event("CATEGORIES:Music, Dance,Arts\\, Crafts\nCATEGORIES:music\nCATEGORIES: Talks ,,")

      expect(event.attributes[:source_categories]).to eq(["Music", "Dance", "Arts, Crafts", "Talks"])
    end

    it "reads the CN of ORGANIZER" do
      expect(ics_event('ORGANIZER;CN="Doe, Jane":mailto:jane@example.com').attributes[:source_organiser]).to eq("Doe, Jane")
      expect(ics_event("ORGANIZER;CN=Folk Club:mailto:folk@example.com").attributes[:source_organiser]).to eq("Folk Club")
    end

    it "stores no organiser for an ORGANIZER without a CN" do
      expect(ics_event("ORGANIZER:mailto:jane@example.com").attributes[:source_organiser]).to be_nil
    end
  end

  describe "JSON-LD" do
    it "reads the organizer's name from a DiceFM venue" do
      fields = imported(CalendarImporter::Parsers::LdJson, :dice_fm_events, "https://dice.fm/venue/folklore-2or7")

      expect(fields.pluck(:source_organiser)).to include("Folklore Hoxton", "Rockfeedback & FORM").and(all(be_present))
      expect(fields.pluck(:source_categories)).to all(be_nil)
    end

    it "reads the organizer's name from a generic page" do
      fields = imported(CalendarImporter::Parsers::LdJson, :heart_of_torbay_events, "https://www.heartoftorbaycic.com/events/")

      expect(fields).to eq([{ source_categories: nil, source_organiser: "Heart of Torbay CIC" }])
    end

    it "reads the organizer's name from OutSavvy event pages" do
      cancelled = imported(CalendarImporter::Parsers::Outsavvy, :outsavvy_cancelled_event, "https://www.outsavvy.com/organiser/a-whole-orange")
      single = imported(CalendarImporter::Parsers::Outsavvy, :outsavvy_publisher_url, "https://www.outsavvy.com/organiser/ldn-queer-mart")

      expect(cancelled.pluck(:source_organiser).tally).to eq("A Whole Orange" => 41, "Vagina Museum" => 10)
      expect(single).to eq([{ source_categories: nil, source_organiser: "LDN QUEER MART" }])
    end

    it "reads an organizer given as a plain string or as several organizers" do
      events = linked_data_events(
        { "organizer" => " Folk Club " },
        { "organizer" => [{ "@type" => "Organization", "name" => "Folk Club" }, { "@type" => "Person", "name" => "Jane Doe" }] }
      )

      expect(source_fields(events).pluck(:source_organiser)).to eq(["Folk Club", "Folk Club, Jane Doe"])
    end

    it "reads keywords given as one comma-separated string or as a list" do
      events = linked_data_events(
        { "keywords" => "music, dance ,Music,," },
        { "keywords" => ["Talks", { "@type" => "DefinedTerm", "name" => "Arts, crafts" }] }
      )

      expect(source_fields(events).pluck(:source_categories)).to eq([%w[music dance], ["Talks", "Arts, crafts"]])
    end

    it "reads values given as JSON-LD value objects" do
      events = linked_data_events(
        { "keywords" => [{ "@value" => "Music", "@language" => "en" }],
          "organizer" => { "@type" => "Organization", "name" => { "@value" => "Folk Club", "@language" => "en" } } }
      )

      expect(source_fields(events)).to eq([{ source_categories: ["Music"], source_organiser: "Folk Club" }])
    end
  end

  describe "Squarespace" do
    let(:squarespace_event) do
      { "id" => "sq-1", "title" => "A Squarespace event", "url" => "/events", "urlId" => "1",
        "startDate" => 1_896_202_800_000, "endDate" => 1_896_210_000_000 }
    end

    it "stores none from a feed whose tags and categories are empty" do
      fields = imported(CalendarImporter::Parsers::Squarespace, "Squarespace_calendar", "https://robin-cunningham-dh7d.squarespace.com/our-events/")

      expect(fields).to be_present.and(all(eq(source_categories: nil, source_organiser: nil)))
    end

    it "reads categories and tags" do
      event = CalendarImporter::Events::SquarespaceEvent.new(
        squarespace_event.merge("categories" => ["Workshops"], "tags" => ["Arts &amp; crafts", "workshops", " "])
      )

      expect(event.attributes[:source_categories]).to eq(["Workshops", "Arts & crafts"])
    end
  end

  describe "importing" do
    let(:calendar) do
      create(:calendar, name: "Generic iCal Calendar", source: "https://www.birchcommunitycentre.co.uk/events.ics", strategy: "place")
    end

    def import
      VCR.use_cassette(:generic_ical_feed, allow_playback_repeats: true) do
        calendar.update!(calendar_state: "in_worker")
        CalendarImporter::CalendarImporterTask.new(calendar, Time.zone.today, true).run
      end
    end

    it "saves the source categories on each event, and fills existing events when the feed is read again" do
      import
      expect(calendar.events.pluck(:source_categories).tally).to eq(["Open"] => 29, ["Activities"] => 16, ["Private"] => 2, nil => 3)

      ids = calendar.events.ids
      calendar.events.update_all(source_categories: nil) # rubocop:disable Rails/SkipsModelValidations
      import

      expect(calendar.events.ids).to match_array(ids)
      expect(calendar.events.pluck(:source_categories).compact.tally).to eq(["Open"] => 29, ["Activities"] => 16, ["Private"] => 2)
    end

    it "saves the source organiser on each event" do
      create(:ldjson_valid_address_hood)
      ld_calendar = create(:calendar, name: "Generic LD+JSON Calendar", source: "https://www.heartoftorbaycic.com/events", strategy: "event")

      VCR.use_cassette(:heart_of_torbay, allow_playback_repeats: true) do
        ld_calendar.update!(calendar_state: "in_worker")
        CalendarImporter::CalendarImporterTask.new(ld_calendar, Time.zone.today, true).run
      end

      expect(ld_calendar.events.pluck(:source_organiser)).to eq(["Heart of Torbay CIC"])
    end
  end
end
