# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "with event locations that can't be read as addresses" do
  let(:url) { "https://calendar.example.org/feed.ics" }
  let(:mapped_ward) { create(:riverside_ward) }
  let!(:calendar) { create(:calendar, source: url, importer_mode: "ical", strategy: "event") }

  def vevent(uid, summary, location)
    start = 2.weeks.from_now.utc.strftime("%Y%m%dT100000Z")
    ["BEGIN:VEVENT", "UID:#{uid}", "DTSTAMP:20261101T000000Z", "DTSTART:#{start}", "SUMMARY:#{summary}",
     ("LOCATION:#{location}" if location), "END:VEVENT"].compact.join("\r\n")
  end

  def serve(*events)
    body = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//PlaceCal//Test//EN", *events, "END:VCALENDAR", ""].join("\r\n")
    stub_request(:get, url).to_return(status: 200, body:, headers: { "Content-Type" => "text/calendar" })
  end

  def geocodes(postcode, codes)
    result = double("GeocoderResult", data: { "latitude" => 53.4, "longitude" => -2.2, "codes" => codes })
    allow(Geocoder).to receive(:search).with(postcode).and_return([result])
  end

  def import(strategy: "event")
    calendar.update!(strategy:, place: (create(:partner) if strategy == "event_override"), calendar_state: "in_worker")
    described_class.new(calendar, Time.zone.today, true).run
    calendar.reload
  end

  before do
    allow(Geocoder).to receive(:search).and_call_original
    allow(Geocoder).to receive(:search).with("ZZ99 9ZZ").and_return([])
    geocodes("M15 5DD", "admin_ward" => "UNMAPPED1", "admin_district" => "UNMAPPED2")
  end

  it "adds one notice per reason, with a count and examples, and still imports the events", :aggregate_failures do
    serve(vevent("a", "Choir", "Church Hall, 1 High Street"),
          vevent("b", "Quiz", "The Pub, 2 Low Road"),
          vevent("c", "Swim", "Baths, 3 Pool Lane, ZZ99 9ZZ"),
          vevent("d", "Walk", "Park Gates, 4 Green Way, M15 5DD"),
          vevent("e", "Online talk", nil))
    import

    expect(calendar.notices).to contain_exactly(
      'Couldn\'t read an address for 2 events because their locations have no postcode, for example "Choir" (Church Hall, 1 High Street) and "Quiz" (The Pub, 2 Low Road).',
      'Couldn\'t read an address for "Swim" (Baths, 3 Pool Lane, ZZ99 9ZZ): its postcode wasn\'t found.',
      'Couldn\'t read an address for "Walk" (Park Gates, 4 Green Way, M15 5DD): its postcode is outside the neighbourhoods PlaceCal covers.'
    )
    expect(calendar.events.pluck(:summary)).to contain_exactly("Choir", "Quiz", "Swim", "Walk", "Online talk")
    expect(calendar.events.where.not(address_id: nil)).to be_empty
  end

  it "names at most three examples" do
    serve(*(1..5).map { |n| vevent("e#{n}", "Session #{n}", "Room #{n}, #{n} High Street") })
    import

    expect(calendar.notices.sole).to start_with("Couldn't read an address for 5 events").and(match(/"Session 1".*"Session 2".*"Session 3"/))
    expect(calendar.notices.sole).not_to include("Session 4")
  end

  it "says so too when the event falls back to the default venue", :aggregate_failures do
    serve(vevent("a", "Choir", "Church Hall, 1 High Street"))
    import(strategy: "event_override")

    expect(calendar.notices.sole).to include('"Choir" (Church Hall, 1 High Street): its location has no postcode')
    expect(calendar.events.sole.place).to eq(calendar.place)
  end

  it "says when a location is only a postcode, with no street line" do
    serve(vevent("a", "Meetup", "M15 5DD"))
    import

    expect(calendar.notices.sole).to eq('Couldn\'t read an address for "Meetup" (M15 5DD): its location has no street line.')
  end

  it "says so under event_override for each reason, as well as falling back to the default venue" do
    serve(vevent("a", "Swim", "Baths, 3 Pool Lane, ZZ99 9ZZ"), vevent("b", "Walk", "Park Gates, 4 Green Way, M15 5DD"))
    import(strategy: "event_override")

    expect(calendar.notices).to contain_exactly(include("its postcode wasn't found"), include("outside the neighbourhoods PlaceCal covers"))
  end

  it "says the location service isn't responding when the lookup times out" do
    allow(Geocoder).to receive(:search).with("ZZ88 8ZZ").and_raise(Geocoder::LookupTimeout)
    serve(vevent("a", "Swim", "Baths, 3 Pool Lane, ZZ88 8ZZ"))
    import

    expect(calendar.notices.sole).to eq('Couldn\'t read an address for "Swim" (Baths, 3 Pool Lane, ZZ88 8ZZ): the location service isn\'t responding.')
  end

  it "adds no notice for an online event whose location is its meeting link" do
    serve(vevent("a", "Online talk", "https://zoom.us/j/123456789"))
    import

    expect(calendar.notices).to be_empty
  end

  it "imports an in-person event whose location is its ticket link, with that link as its webpage", :aggregate_failures do
    serve(vevent("a", "Gig", "https://tickets.example.com/gig"))
    import

    expect(calendar.notices).to be_empty
    event = calendar.events.sole
    expect(event.online_address).to be_nil
    expect(event.publisher_url).to eq("https://tickets.example.com/gig")
    expect(event.address).to be_nil
  end

  it "adds no notice for readable addresses or events with no location" do
    mapped_ward
    geocodes("M15 5DD", "admin_ward" => mapped_ward.unit_code_value, "admin_district" => "E08000003")
    serve(vevent("a", "Walk", "Park Gates, 4 Green Way, M15 5DD"), vevent("b", "Online talk", nil))
    import

    expect(calendar.notices).to be_empty
  end
end
