# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::OccurrenceSync do
  let(:calendar) { VCR.use_cassette(:import_test_calendar) { create(:calendar, strategy: "no_location") } }
  let(:uid) { "sync-123" }

  def sync(times, series:, from_date: times.first[0], summary: "An event")
    described_class.new(
      calendar:,
      uid:,
      from_date:,
      occurrences: times.map { |start, finish| CalendarImporter::Events::Base::Occurrence.new(start_time: start, end_time: finish) },
      series:,
      attributes_for: ->(_occurrence) { { uid:, summary:, organiser_id: calendar.organiser_id } }
    ).call
  end

  def create_row(start, finish, summary: "Row at #{start}")
    Event.create!(calendar:, uid:, summary:, dtstart: start, dtend: finish, organiser_id: calendar.organiser_id)
  end

  def rows
    calendar.events.where(uid:).order(:dtstart)
  end

  def destroy_versions
    PaperTrail::Version.where(item_type: "Event", event: "destroy").count
  end

  describe "a series" do
    let(:occ1) { [DateTime.new(2024, 1, 8, 10, 0), DateTime.new(2024, 1, 8, 11, 0)] }
    let(:occ2) { [DateTime.new(2024, 1, 15, 10, 0), DateTime.new(2024, 1, 15, 11, 0)] }

    it "matches rows on exact times and leaves identical rows unchanged", :aggregate_failures do
      first = sync([occ1, occ2], series: true)
      expect(first.created.size).to eq(2)

      second = sync([occ1, occ2], series: true)

      expect(rows.count).to eq(2)
      expect(second.unchanged).to match_array(first.created)
      expect(second).to have_attributes(created: [], updated: [], removed: [], failures: [])
    end

    it "removes stale rows with destroy_all when the schedule changes", :aggregate_failures do
      sync([occ1, occ2], series: true)
      stale = rows.last

      result = nil
      expect { result = sync([occ1], series: true) }.to change { destroy_versions }.by(1)

      expect(rows.pluck(:dtstart)).to eq([occ1[0]])
      expect(result.removed).to eq([stale])
    end

    it "matches start and end as a pair, not independently", :aggregate_failures do
      occ2 = [DateTime.new(2024, 1, 15, 10, 0), DateTime.new(2024, 1, 15, 12, 0)]
      sync([occ1, occ2], series: true)

      new_occ2 = [occ2[0], DateTime.new(2024, 1, 15, 13, 0)]
      sync([occ1, new_occ2], series: true)

      expect(rows.pluck(:dtstart, :dtend)).to eq([occ1, new_occ2])
    end
  end

  describe "a one-off" do
    let(:from_date) { DateTime.new(2024, 1, 1) }
    let(:occurrence) { [DateTime.new(2024, 1, 15, 10, 0), DateTime.new(2024, 1, 15, 11, 0)] }

    it "matches a row on exact times before an earlier upcoming row", :aggregate_failures do
      earlier = create_row(DateTime.new(2024, 1, 8, 10, 0), DateTime.new(2024, 1, 8, 11, 0))
      row = create_row(*occurrence)

      result = sync([occurrence], series: false, from_date:)

      expect(rows).to eq([row])
      expect(result.updated).to eq([row])
      expect(result.removed).to eq([earlier])
      expect(row.reload.summary).to eq("An event")
    end

    it "falls back to the first upcoming row and removes the other upcoming rows", :aggregate_failures do
      later = create_row(DateTime.new(2024, 3, 1, 10, 0), DateTime.new(2024, 3, 1, 11, 0))
      past = create_row(DateTime.new(2023, 12, 1, 10, 0), DateTime.new(2023, 12, 1, 11, 0))
      upcoming = create_row(DateTime.new(2024, 2, 1, 10, 0), DateTime.new(2024, 2, 1, 11, 0))

      result = sync([occurrence], series: false, from_date:)

      expect(rows).to eq([past, upcoming])
      expect(upcoming.reload).to have_attributes(dtstart: occurrence[0], dtend: occurrence[1])
      expect(result.updated).to eq([upcoming])
      expect(result.removed).to eq([later])
    end

    it "falls back to the first row of any date when none is upcoming", :aggregate_failures do
      past = create_row(DateTime.new(2023, 12, 1, 10, 0), DateTime.new(2023, 12, 1, 11, 0))
      earliest = create_row(DateTime.new(2023, 11, 1, 10, 0), DateTime.new(2023, 11, 1, 11, 0))

      result = sync([occurrence], series: false, from_date:)

      expect(rows).to eq([past, earliest])
      expect(earliest.reload).to have_attributes(dtstart: occurrence[0], dtend: occurrence[1])
      expect(result.updated).to eq([earliest])
    end
  end

  it "removes other rows at the same time with delete_all", :aggregate_failures do
    start = DateTime.new(2024, 1, 8, 10, 0)
    finish = DateTime.new(2024, 1, 8, 11, 0)
    ActiveRecord::Base.connection.remove_index :events, name: "index_events_unique_per_calendar"
    3.times do
      Event.new(calendar:, uid:, summary: "Duplicate", dtstart: start, dtend: finish, organiser_id: calendar.organiser_id).save!(validate: false)
    end

    result = nil
    expect { result = sync([[start, finish]], series: true) }.not_to(change { destroy_versions })

    expect(rows.count).to eq(1)
    expect(result.removed.size).to eq(2)
    expect(result.removed).not_to include(rows.sole)
  ensure
    unless ActiveRecord::Base.connection.index_exists?(:events, name: "index_events_unique_per_calendar")
      ActiveRecord::Base.connection.add_index :events, %i[calendar_id uid dtstart dtend],
                                              unique: true,
                                              name: "index_events_unique_per_calendar"
    end
  end

  it "updates the existing row when a new row hits the unique index", :aggregate_failures do
    start = DateTime.new(2024, 1, 8, 10, 0)
    finish = DateTime.new(2024, 1, 8, 11, 0)
    raced = false
    allow(Event).to receive(:new).and_wrap_original do |original, *args, &block|
      unless raced
        raced = true
        create_row(start, finish, summary: "Raced")
      end
      original.call(*args, &block)
    end

    result = sync([[start, finish]], series: true)

    expect(rows.sole.summary).to eq("An event")
    expect(result.updated).to eq([rows.sole])
    expect(result).to have_attributes(created: [], failures: [])
  end

  describe "are_spaces_available" do
    let(:from_date) { Time.zone.local(2030, 1, 1) }

    def sync_event(data)
      described_class.new(
        calendar:,
        uid: data.uid,
        from_date:,
        occurrences: data.occurrences_between(from_date, from_date + 1.year),
        series: true,
        attributes_for: ->(occurrence) { data.attributes_for(occurrence).merge(organiser_id: calendar.organiser_id) }
      ).call
    end

    def row_for(data)
      calendar.events.find_by!(uid: data.uid)
    end

    it "writes an occurrence's status" do
      data = CalendarImporter::Events::TicketsolveEvent.new(Nokogiri::XML(<<~XML).at_css("show"))
        <show id="ts-1">
          <name>A show</name>
          <description>About the show</description>
          <url>https://example.ticketsolve.com/shows/1</url>
          <events><event><opening_time_iso>2030-02-01T19:00:00+00:00</opening_time_iso><status>available</status></event></events>
        </show>
      XML

      sync_event(data)

      expect(row_for(data).are_spaces_available).to eq("available")
    end

    it "clears it when the source's occurrences have no status" do
      data = CalendarImporter::Events::TickettailorEvent.new(
        "id" => "tt-1",
        "name" => "A Ticket Tailor event",
        "start" => { "date" => "2030-02-01", "time" => "19:00", "tz" => "UTC" },
        "end" => { "date" => "2030-02-01", "time" => "21:00", "tz" => "UTC" }
      )
      sync_event(data)
      row_for(data).update!(are_spaces_available: "Sold out")

      sync_event(data)

      expect(row_for(data).are_spaces_available).to be_nil
    end

    it "leaves it untouched for iCal occurrences" do
      ical = Icalendar::Calendar.parse(<<~ICS).first.events.first
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
      data = CalendarImporter::Events::IcsEvent.new(ical, ical.dtstart, ical.dtend)
      sync_event(data)
      row_for(data).update!(are_spaces_available: "Sold out")

      sync_event(data)

      expect(row_for(data).are_spaces_available).to eq("Sold out")
    end
  end

  it "reports a failed save with its errors", :aggregate_failures do
    result = sync([[DateTime.new(2024, 1, 8, 10, 0), DateTime.new(2024, 1, 8, 11, 0)]], series: false, summary: "")

    expect(rows).to be_empty
    expect(result.failures.size).to eq(1)
    expect(result.failures.sole.errors.full_messages).to eq(["Summary can't be blank"])
    expect(result).to have_attributes(created: [], updated: [], unchanged: [])
  end
end
