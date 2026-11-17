# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event images from sources" do
  def image_urls(parser, cassette, url, **calendar_attributes)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      calendar = build(:calendar, source: url, **calendar_attributes)
      parser.new(calendar).calendar_to_events.events.map { |event| event.attributes[:image_source_url] }
    end
  end

  def linked_data_event(image)
    data = { "@type" => "Event", "name" => "An event", "url" => "https://example.com/1", "startDate" => "2030-02-01T19:00", "image" => image }
    html = %(<script type="application/ld+json">#{{ '@context' => 'https://schema.org', '@graph' => [data] }.to_json}</script>)
    consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
    consumer.consume(CalendarImporter::Parsers::Base.parse_ld_json_document(Nokogiri::HTML(html)))
    consumer.events.first
  end

  it "reads Eventbrite's original logo" do
    urls = image_urls(CalendarImporter::Parsers::Eventbrite, :eventbrite_events, "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483")

    expect(urls).to be_present.and(all(start_with("https://img.evbuc.com/")))
  end

  it "reads Ticket Tailor's header image" do
    urls = image_urls(CalendarImporter::Parsers::Tickettailor, :tickettailor_events, "https://www.tickettailor.com/events/testorg",
                      api_token: "sk_test_placeholder")

    expect(urls).to be_present.and(all(start_with("https://uploads.tickettailorassets.com/")))
  end

  it "reads Squarespace's asset URL" do
    urls = image_urls(CalendarImporter::Parsers::Squarespace, "Squarespace_calendar", "https://robin-cunningham-dh7d.squarespace.com/our-events/")

    expect(urls).to be_present.and(all(start_with("https://images.squarespace-cdn.com/")))
  end

  it "reads a JSON-LD image given as a URL, an ImageObject or a list" do
    expect(linked_data_event("https://example.com/a.jpg").attributes[:image_source_url]).to eq("https://example.com/a.jpg")
    expect(linked_data_event({ "@type" => "ImageObject", "url" => "https://example.com/b.jpg" }).attributes[:image_source_url])
      .to eq("https://example.com/b.jpg")
    expect(linked_data_event(["https://example.com/c.jpg", "https://example.com/d.jpg"]).attributes[:image_source_url])
      .to eq("https://example.com/c.jpg")
  end

  it "gives no image for a JSON-LD event without one, or for iCal" do
    expect(linked_data_event(nil).attributes[:image_source_url]).to be_nil
    expect(image_urls(CalendarImporter::Parsers::Ics, :generic_ical_feed, "https://www.birchcommunitycentre.co.uk/events.ics").uniq).to eq([nil])
  end

  it "stores each event's image when importing" do
    stub_request(:get, %r{\Ahttps://images\.squarespace-cdn\.com/})
      .to_return(body: file_fixture("good-cat-picture.jpg").read, headers: { "Content-Type" => "image/jpeg" })
    calendar = create(:calendar, source: "https://robin-cunningham-dh7d.squarespace.com/our-events/", strategy: "place")

    VCR.use_cassette("Squarespace_calendar", allow_playback_repeats: true) do
      calendar.update!(calendar_state: "in_worker")
      CalendarImporter::CalendarImporterTask.new(calendar, Time.zone.today, true).run
    end

    expect(calendar.events).to be_present
    expect(calendar.events.map { |event| event.image.present? }).to all(be(true))
  end
end
