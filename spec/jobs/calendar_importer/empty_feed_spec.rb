# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "with an empty feed" do
  let(:url) { "https://calendar.example.org/feed.ics" }
  let(:empty_feed) { "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//PlaceCal//Test//EN\r\nEND:VCALENDAR\r\n" }
  let(:full_feed) do
    <<~ICS.gsub("\n", "\r\n")
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//PlaceCal//Test//EN
      BEGIN:VEVENT
      UID:still-on@example.org
      DTSTAMP:20261101T000000Z
      DTSTART:#{2.weeks.from_now.utc.strftime('%Y%m%dT100000Z')}
      DTEND:#{2.weeks.from_now.utc.strftime('%Y%m%dT120000Z')}
      SUMMARY:Still on
      END:VEVENT
      END:VCALENDAR
    ICS
  end
  let!(:calendar) { create(:calendar, source: url, importer_mode: "ical", strategy: "no_location") }
  let!(:upcoming_event) do
    create(:event, calendar:, organiser: calendar.organiser, dtstart: 1.month.from_now, dtend: 1.month.from_now + 2.hours)
  end
  let!(:past_event) { create(:past_event, calendar:, organiser: calendar.organiser) }

  def serve(body)
    stub_request(:get, url).to_return(status: 200, body:, headers: { "Content-Type" => "text/calendar" })
  end

  def import(force: false)
    calendar.update!(calendar_state: "in_worker")
    described_class.new(calendar, Time.zone.today, force).run
    calendar.reload
  end

  it "keeps the events and says so when a changed feed parses to no events", :aggregate_failures do
    serve(empty_feed)
    import

    expect(Event.exists?(upcoming_event.id)).to be(true)
    expect(calendar.feed_empty_since).to be_within(1.minute).of(Time.current)
    expect(calendar.notices.join).to include("no events since 8 November 2022", "upcoming event stays listed until 10 November 2022")
  end

  it "keeps the events, the first date and the notice on later imports of the same empty feed", :aggregate_failures do
    serve(empty_feed)
    import
    first_date = calendar.feed_empty_since
    Timecop.freeze(47.hours.from_now)
    import
    import(force: true)

    expect(Event.exists?(upcoming_event.id)).to be(true)
    expect(calendar.feed_empty_since).to eq(first_date)
    expect(calendar.notices.join).to include("no events since 8 November 2022")
  end

  it "keeps the first date when the feed changes but is still empty" do
    serve(empty_feed)
    import
    first_date = calendar.feed_empty_since
    Timecop.freeze(1.day.from_now)
    serve(empty_feed.sub("PRODID:-//PlaceCal//Test//EN", "PRODID:-//PlaceCal//Other//EN"))
    import

    expect(calendar.feed_empty_since).to eq(first_date)
  end

  it "removes upcoming events, but not past ones, once the feed has stayed empty for 48 hours", :aggregate_failures do
    serve(empty_feed)
    import
    Timecop.freeze(48.hours.from_now + 1.minute)
    import

    expect(Event.exists?(upcoming_event.id)).to be(false)
    expect(Event.exists?(past_event.id)).to be(true)
    expect(calendar.notices.join).to include("upcoming events have been removed")

    import
    expect(calendar.notices).to eq(["The feed has had no events since 8 November 2022."])
  end

  it "says the feed is empty, without claiming a removal, when nothing is upcoming", :aggregate_failures do
    upcoming_event.destroy!
    serve(empty_feed)
    import
    expect(calendar.notices).to eq(["The feed has had no events since 8 November 2022."])

    Timecop.freeze(8.days.from_now)
    import
    expect(calendar.notices).to eq(["The feed has had no events since 8 November 2022."])
  end

  it "doesn't act on an empty feed whose calendar was edited during the import", :aggregate_failures do
    serve(empty_feed)
    import
    Timecop.freeze(8.days.from_now)
    running_import = Calendar.find(calendar.id).tap { |c| c.update!(calendar_state: "in_worker") }
    calendar.update!(source: "https://calendar.example.org/new-feed.ics")

    described_class.new(running_import, Time.zone.today, false).run

    expect(Event.exists?(upcoming_event.id)).to be(true)
    expect(calendar.reload.feed_empty_since).to be_nil
  end

  it "forgets the empty spell when the feed has events again", :aggregate_failures do
    serve(empty_feed)
    import
    serve(full_feed)
    import
    Timecop.freeze(8.days.from_now)
    import

    expect(calendar.feed_empty_since).to be_nil
    expect(calendar.events.upcoming.pluck(:summary)).to include("Still on")
  end

  it "leaves events alone when the feed can't be fetched", :aggregate_failures do
    allow(CalendarImporter::Parsers::Base).to receive(:sleep)
    stub_request(:get, url).to_return(status: 500)

    expect { import }.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed)
    expect(Event.exists?(upcoming_event.id)).to be(true)
    expect(calendar.reload.feed_empty_since).to be_nil
  end

  it "deletes nothing on an import of an unchanged feed with events", :aggregate_failures do
    serve(full_feed)
    import(force: true)
    expect { import }.not_to(change { calendar.events.count })
    expect(calendar.feed_empty_since).to be_nil
  end
end
