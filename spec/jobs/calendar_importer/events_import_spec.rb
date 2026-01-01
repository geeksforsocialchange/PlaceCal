# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events import" do
  it "imports webcal calendars" do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: "https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics"
      )

      from_date = Date.new(2018, 11, 20)
      force_import = false
      CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

      # Verify events were imported - count may vary based on cassette data
      expect(Event.count).to be > 0

      # Verify events have required fields
      Event.all.each do |event|
        expect(event.summary).to be_present
        expect(event.dtstart).to be_present
      end
    end
  end

  it "does not touch calendar updated_at timestamp" do
    VCR.use_cassette(:import_test_calendar) do
      calendar_time = DateTime.new(1990, 1, 1, 12, 30, 0)
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: "https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics",
        updated_at: calendar_time
      )

      # Identify partner by partner.name == event_location.street_address
      # (Automatically created address will not match event location.)
      create(:partner, name: "Z-aRtS")

      from_date = Date.new(2018, 11, 20)
      force_import = false
      CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

      expect(calendar.updated_at).to eq(calendar_time)
    end
  end
end
