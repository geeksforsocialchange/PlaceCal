# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importer event classes" do
  def self.event_class_names
    Rails.root.glob("app/jobs/calendar_importer/events/*.rb").map { |path| path.basename(".rb").to_s.camelize } - ["Base"]
  end

  let(:ics) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//PlaceCal//Test//EN
      BEGIN:VEVENT
      UID:ics-1
      DTSTART:20300201T190000Z
      DTEND:20300201T210000Z
      SUMMARY:An iCal event
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  let(:manchester_uni) do
    <<~XML
      <ns:events xmlns:ns="http://example.com/events">
        <ns:event>
          <ns:id>mu-1</ns:id>
          <ns:title>A lecture</ns:title>
          <ns:description>About the lecture</ns:description>
          <ns:times type="local">
            <ns:start><ns:date>2030-02-01</ns:date><ns:time>19:00:00</ns:time></ns:start>
            <ns:end><ns:date>2030-02-01</ns:date><ns:time>21:00:00</ns:time></ns:end>
          </ns:times>
        </ns:event>
      </ns:events>
    XML
  end

  let(:ticketsolve) do
    <<~XML
      <show id="ts-1">
        <name>A show</name>
        <description>About the show</description>
        <url>https://example.ticketsolve.com/shows/1</url>
        <events><event><opening_time_iso>2030-02-01T19:00:00+00:00</opening_time_iso><status>available</status></event></events>
      </show>
    XML
  end

  let(:linked_data) do
    {
      "url" => "https://example.com/events/1",
      "name" => "A linked data event",
      "start_date" => { "@value" => "2030-02-01T19:00:00+00:00" },
      "end_date" => { "@value" => "2030-02-01T21:00:00+00:00" }
    }
  end

  let(:arguments) do
    ical = Icalendar::Calendar.parse(ics).first.events.first
    {
      "EventbriteEvent" => [{ "id" => "eb-1", "name" => { "text" => "An Eventbrite event" }, "description" => { "html" => "<p>About</p>" },
                              "url" => "https://www.eventbrite.co.uk/e/1",
                              "start" => { "utc" => "2030-02-01T19:00:00Z" }, "end" => { "utc" => "2030-02-01T21:00:00Z" } }],
      "IcsEvent" => [ical, ical.dtstart, ical.dtend],
      "LinkedDataEvent" => [linked_data],
      "ManchesterUniEvent" => [Nokogiri::XML(manchester_uni).at_xpath("//ns:event")],
      "OutsavvyEvent" => [linked_data],
      "ResidentAdvisor" => [{ "id" => "ra-1", "title" => "A night", "contentUrl" => "/events/1",
                              "startTime" => "2030-02-01T19:00:00", "endTime" => "2030-02-01T23:00:00" }],
      "SquarespaceEvent" => [{ "id" => "sq-1", "title" => "A Squarespace event", "body" => "<p>About</p>", "url" => "/events", "urlId" => "1",
                               "startDate" => 1_896_202_800_000, "endDate" => 1_896_210_000_000 }],
      "TicketsolveEvent" => [Nokogiri::XML(ticketsolve).at_css("show")],
      "TicketsourceEvent" => [{ "id" => "tso-1", "attributes" => { "name" => "A TicketSource event" },
                                "date" => { "id" => "d1", "attributes" => { "start" => "2030-02-01T19:00:00Z", "end" => "2030-02-01T21:00:00Z" } } }],
      "TickettailorEvent" => [{ "id" => "tt-1", "name" => "A Ticket Tailor event",
                                "start" => { "date" => "2030-02-01", "time" => "19:00", "tz" => "UTC" },
                                "end" => { "date" => "2030-02-01", "time" => "21:00", "tz" => "UTC" } }],
      "WixEvent" => [{ "id" => "wix-1", "title" => "A Wix event",
                       "scheduling" => { "config" => { "startDate" => "2030-02-01T19:00:00Z", "endDate" => "2030-02-01T21:00:00Z" } } }]
    }
  end

  it "has an example for every class" do
    expect(arguments.keys).to match_array(self.class.event_class_names)
  end

  event_class_names.each do |class_name|
    describe class_name do
      subject(:event) { "CalendarImporter::Events::#{class_name}".constantize.new(*arguments.fetch(class_name)) }

      it "answers the fields the importer reads" do
        expect(event).to respond_to(:uid, :summary, :description, :location, :publisher_url, :occurrences_between)
      end

      it "returns occurrences with a start and end", :aggregate_failures do
        occurrences = event.occurrences_between(Time.zone.local(2030, 1, 1), Time.zone.local(2031, 1, 1))

        expect(occurrences).to be_present
        expect(occurrences).to all(be_a(CalendarImporter::Events::Base::Occurrence))
        expect(occurrences).to all(respond_to(:start_time, :end_time))
        expect(occurrences.map(&:start_time)).to all(be_present)
      end
    end
  end
end
