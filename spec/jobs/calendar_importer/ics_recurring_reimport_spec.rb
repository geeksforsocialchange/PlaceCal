# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reimporting recurring iCal events" do
  let(:calendar) { create(:ics_calendar, strategy: "no_location", importer_mode: "ical") }

  def vevent(uid: "weekly@example.com", start: "20261104T190000", finish: "20261104T200000", rrule: "FREQ=WEEKLY;COUNT=4", summary: "Weekly")
    lines = ["BEGIN:VEVENT", "UID:#{uid}", "DTSTART;TZID=Europe/London:#{start}", "DTEND;TZID=Europe/London:#{finish}"]
    lines << "RRULE:#{rrule}" if rrule
    lines += ["SUMMARY:#{summary}", "END:VEVENT"]
    "#{lines.join("\n")}\n"
  end

  def feed(*vevents)
    "BEGIN:VCALENDAR\nVERSION:2.0\n#{vevents.join}END:VCALENDAR\n"
  end

  def import(ics)
    stub_request(:get, calendar.source).to_return(status: 200, body: ics)
    calendar.update!(calendar_state: "in_worker")
    CalendarImporter::CalendarImporterTask.new(calendar, Time.current, true).run
  end

  def listed(scope = calendar.events)
    scope.order(:dtstart).map { |event| [event.dtstart.in_time_zone.strftime("%-d %b"), event.summary] }
  end

  before { Timecop.freeze(Time.zone.local(2026, 10, 29, 12)) }

  describe "past occurrences" do
    it "keeps them when a changed series is reimported" do
      import(feed(vevent(rrule: "FREQ=WEEKLY;COUNT=6")))
      past_ids = calendar.events.where(dtstart: ...Time.zone.local(2026, 11, 20)).order(:dtstart).pluck(:id)

      Timecop.freeze(Time.zone.local(2026, 11, 20, 12)) do
        import(feed(vevent(rrule: "FREQ=WEEKLY;COUNT=5", summary: "Renamed")))
      end

      expect(listed).to eq([
                             ["4 Nov", "Weekly"],
                             ["11 Nov", "Weekly"],
                             ["18 Nov", "Weekly"],
                             ["25 Nov", "Renamed"],
                             ["2 Dec", "Renamed"]
                           ])
      expect(calendar.events.where(dtstart: ...Time.zone.local(2026, 11, 20)).order(:dtstart).pluck(:id)).to eq(past_ids)
    end
  end

  describe "a series that becomes a one-off" do
    it "leaves exactly one upcoming event for the UID" do
      import(feed(vevent))

      import(feed(vevent(start: "20261106T190000", finish: "20261106T200000", rrule: nil, summary: "One-off")))

      expect(listed).to eq([["6 Nov", "One-off"]])
    end

    it "keeps the series' past occurrences" do
      import(feed(vevent))

      Timecop.freeze(Time.zone.local(2026, 11, 12, 12)) do
        import(feed(vevent(start: "20261120T190000", finish: "20261120T200000", rrule: nil, summary: "One-off")))

        expect(listed(calendar.events.upcoming)).to eq([["20 Nov", "One-off"]])
      end
      expect(listed).to eq([["4 Nov", "Weekly"], ["11 Nov", "Weekly"], ["20 Nov", "One-off"]])
    end

    it "keeps a rescheduled one-off as the same event" do
      import(feed(vevent(rrule: nil)))
      id = calendar.events.sole.id

      import(feed(vevent(start: "20261106T190000", finish: "20261106T200000", rrule: nil)))

      expect(calendar.events.sole).to have_attributes(id:, dtstart: Time.zone.local(2026, 11, 6, 19))
    end
  end

  describe "occurrence limits" do
    it "imports a minutely event up to the limit and says so" do
      stub_const("CalendarImporter::EventResolver::MAX_OCCURENCES", 25)
      allow(Calendar).to receive(:import_up_to).and_return(1.day.from_now)

      import(feed(vevent(start: "20261029T130000", finish: "20261029T130500", rrule: "FREQ=MINUTELY", summary: "Every minute")))

      expect(calendar.events.count).to eq(25)
      expect(calendar.events.minimum(:dtstart)).to eq(Time.zone.local(2026, 10, 29, 13))
      expect(calendar.events.maximum(:dtstart)).to eq(Time.zone.local(2026, 10, 29, 13, 24))
      expect(calendar.reload.notices).to eq(["\"Every minute\" repeats more than 25 times, so only its first 25 dates were imported."])
    end

    it "stops at the calendar limit without removing events it did not reach" do
      first = vevent(uid: "first@example.com", summary: "First")
      second = vevent(uid: "second@example.com", summary: "Second")
      import(feed(first, second))

      stub_const("CalendarImporter::CalendarImporterTask::MAX_OCCURENCES", 6)
      import(feed(vevent(uid: "first@example.com", summary: "First edited"), vevent(uid: "second@example.com", summary: "Second edited")))

      expect(calendar.events.group(:summary).count).to eq("First edited" => 4, "Second" => 4)
      expect(calendar.reload.notices).to eq([
                                              "This calendar has more than 6 upcoming event dates, so the import stopped there. " \
                                              "Events after that point were not updated."
                                            ])
    end
  end
end
