# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importing iCal series with edited occurrences" do
  let(:calendar) { create(:ics_calendar, strategy: "no_location", importer_mode: "ical") }

  let(:series) do
    <<~ICS
      BEGIN:VEVENT
      UID:weekly@example.com
      DTSTART;TZID=Europe/London:20261104T190000
      DTEND;TZID=Europe/London:20261104T200000
      RRULE:FREQ=WEEKLY;COUNT=4
      SUMMARY:Weekly
      END:VEVENT
    ICS
  end

  let(:moved) do
    <<~ICS
      BEGIN:VEVENT
      UID:weekly@example.com
      RECURRENCE-ID;TZID=Europe/London:20261111T190000
      DTSTART;TZID=Europe/London:20261111T210000
      DTEND;TZID=Europe/London:20261111T220000
      SUMMARY:Moved
      END:VEVENT
    ICS
  end

  before { Timecop.freeze(Time.zone.local(2026, 10, 29, 12)) }

  def feed(*vevents)
    "BEGIN:VCALENDAR\nVERSION:2.0\n#{vevents.join}END:VCALENDAR\n"
  end

  def import(ics)
    stub_request(:get, calendar.source).to_return(status: 200, body: ics)
    calendar.update!(calendar_state: "in_worker")
    CalendarImporter::CalendarImporterTask.new(calendar, Time.current, true).run
  end

  def listed
    calendar.events.order(:dtstart).map do |event|
      [event.dtstart.in_time_zone.strftime("%-d %b %H:%M"), event.dtend.in_time_zone.strftime("%H:%M"), event.summary]
    end
  end

  it "shows a moved occurrence at its new time when the series comes first" do
    import(feed(series, moved))

    expect(listed).to eq([
                           ["4 Nov 19:00", "20:00", "Weekly"],
                           ["11 Nov 21:00", "22:00", "Moved"],
                           ["18 Nov 19:00", "20:00", "Weekly"],
                           ["25 Nov 19:00", "20:00", "Weekly"]
                         ])
  end

  it "shows a moved occurrence at its new time when the moved occurrence comes first" do
    import(feed(moved, series))

    expect(listed).to eq([
                           ["4 Nov 19:00", "20:00", "Weekly"],
                           ["11 Nov 21:00", "22:00", "Moved"],
                           ["18 Nov 19:00", "20:00", "Weekly"],
                           ["25 Nov 19:00", "20:00", "Weekly"]
                         ])
  end

  it "moves an occurrence that was imported before it was edited" do
    import(feed(series))
    import(feed(series, moved))

    expect(listed.map(&:first)).to eq(["4 Nov 19:00", "11 Nov 21:00", "18 Nov 19:00", "25 Nov 19:00"])
  end

  it "puts an occurrence back when its edit is removed from the feed" do
    import(feed(series, moved))
    import(feed(series))

    expect(listed.map(&:first)).to eq(["4 Nov 19:00", "11 Nov 19:00", "18 Nov 19:00", "25 Nov 19:00"])
  end

  it "drops an occurrence cancelled with STATUS:CANCELLED" do
    cancelled = <<~ICS
      BEGIN:VEVENT
      UID:weekly@example.com
      RECURRENCE-ID;TZID=Europe/London:20261118T190000
      DTSTART;TZID=Europe/London:20261118T190000
      DTEND;TZID=Europe/London:20261118T200000
      STATUS:CANCELLED
      SUMMARY:Weekly
      END:VEVENT
    ICS

    import(feed(series))
    import(feed(cancelled, series))

    expect(listed.map(&:first)).to eq(["4 Nov 19:00", "11 Nov 19:00", "25 Nov 19:00"])
  end

  it "drops an occurrence removed with EXDATE" do
    import(feed(series))
    import(feed(series.sub("RRULE", "EXDATE;TZID=Europe/London:20261125T190000\nRRULE")))

    expect(listed.map(&:first)).to eq(["4 Nov 19:00", "11 Nov 19:00", "18 Nov 19:00"])
  end

  it "changes nothing when the same feed is imported again" do
    import(feed(moved, series))
    before = calendar.events.order(:dtstart).pluck(:id, :updated_at)

    Timecop.travel(1.hour) { import(feed(moved, series)) }

    expect(calendar.events.order(:dtstart).pluck(:id, :updated_at)).to eq(before)
  end

  it "keeps the series' place on a moved occurrence" do
    calendar.update!(strategy: "place", place: calendar.organiser)
    import(feed(series, moved))

    expect(calendar.events.pluck(:summary, :place_id).uniq).to contain_exactly(["Weekly", calendar.place.id], ["Moved", calendar.place.id])
  end

  it "imports an edited occurrence whose series is missing from the feed" do
    import(feed(moved))

    expect(listed).to eq([["11 Nov 21:00", "22:00", "Moved"]])
  end
end
