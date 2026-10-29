# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importing iCal times without a time zone" do
  let(:calendar) { create(:ics_calendar, strategy: "no_location", importer_mode: "ical") }

  before { Timecop.freeze(Time.zone.local(2026, 10, 29, 12)) }

  def vevent(uid, *lines)
    "BEGIN:VEVENT\nUID:#{uid}\nSUMMARY:#{uid}\n#{lines.join("\n")}\nEND:VEVENT\n"
  end

  def import(*vevents)
    stub_request(:get, calendar.source).to_return(status: 200, body: "BEGIN:VCALENDAR\nVERSION:2.0\n#{vevents.join}END:VCALENDAR\n")
    calendar.update!(calendar_state: "in_worker")
    CalendarImporter::CalendarImporterTask.new(calendar, Time.current, true).run
  end

  def listed(uid)
    calendar.events.where(uid:).order(:dtstart).map do |event|
      "#{event.dtstart.in_time_zone.strftime('%-d %b %H:%M')} to #{event.dtend.in_time_zone.strftime('%-d %b %H:%M')}"
    end
  end

  %w[UTC Europe/London America/New_York].each do |process_zone|
    context "when the server runs in #{process_zone}" do
      around do |example|
        original = ENV.fetch("TZ", nil)
        ENV["TZ"] = process_zone
        example.run
      ensure
        ENV["TZ"] = original
      end

      it "starts all-day events at midnight in London, in summer and winter" do
        import(vevent("summer", "DTSTART;VALUE=DATE:20270705", "DTEND;VALUE=DATE:20270706"),
               vevent("winter", "DTSTART;VALUE=DATE:20261105", "DTEND;VALUE=DATE:20261106"))

        expect(listed("summer")).to eq(["5 Jul 00:00 to 6 Jul 00:00"])
        expect(listed("winter")).to eq(["5 Nov 00:00 to 6 Nov 00:00"])
      end

      it "reads floating times as London wall-clock times, in summer and winter" do
        import(vevent("summer", "DTSTART:20270705T190000", "DTEND:20270705T210000"),
               vevent("winter", "DTSTART:20261105T190000", "DTEND:20261105T210000"))

        expect(listed("summer")).to eq(["5 Jul 19:00 to 5 Jul 21:00"])
        expect(listed("winter")).to eq(["5 Nov 19:00 to 5 Nov 21:00"])
      end

      it "keeps a floating weekly event at the same London time across the clock change" do
        import(vevent("weekly", "DTSTART:20270324T190000", "DTEND:20270324T200000", "RRULE:FREQ=WEEKLY;COUNT=2"))

        expect(listed("weekly")).to eq(["24 Mar 19:00 to 24 Mar 20:00", "31 Mar 19:00 to 31 Mar 20:00"])
      end

      it "drops an all-day occurrence removed with EXDATE" do
        import(vevent("daily", "DTSTART;VALUE=DATE:20261102", "DTEND;VALUE=DATE:20261103", "RRULE:FREQ=DAILY;COUNT=3", "EXDATE;VALUE=DATE:20261103"))

        expect(listed("daily")).to eq(["2 Nov 00:00 to 3 Nov 00:00", "4 Nov 00:00 to 5 Nov 00:00"])
      end

      it "moves a floating occurrence edited with RECURRENCE-ID" do
        import(vevent("weekly", "DTSTART:20261104T190000", "DTEND:20261104T200000", "RRULE:FREQ=WEEKLY;COUNT=2"),
               vevent("weekly", "RECURRENCE-ID:20261111T190000", "DTSTART:20261111T210000", "DTEND:20261111T220000"))

        expect(listed("weekly")).to eq(["4 Nov 19:00 to 4 Nov 20:00", "11 Nov 21:00 to 11 Nov 22:00"])
      end

      it "leaves times with a TZID or in UTC unchanged" do
        import(vevent("new-york", "DTSTART;TZID=America/New_York:20270705T190000", "DTEND;TZID=America/New_York:20270705T200000"),
               vevent("utc", "DTSTART:20270705T180000Z", "DTEND:20270705T190000Z"))

        expect(listed("new-york")).to eq(["6 Jul 00:00 to 6 Jul 01:00"])
        expect(listed("utc")).to eq(["5 Jul 19:00 to 5 Jul 20:00"])
      end
    end
  end
end
