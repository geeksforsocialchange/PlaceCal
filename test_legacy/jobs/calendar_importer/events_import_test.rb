# frozen_string_literal: true

require 'test_helper'

class EventsImportTest < ActiveSupport::TestCase
  test 'imports webcal calendars' do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'
      )

      # Identify partner by partner.name == event_location.street_address
      # (Automatically created address will not match event location.)
      partner = create(:partner, name: 'Z-aRtS')
      partner.address.postcode = 'M15 5ZA'
      partner.save!

      from_date = Date.new(2018, 11, 20)
      force_import = false
      CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

      # Did all events import?

      assert_equal 11, Event.count

      # Each partner created above will automatically create one address.
      # All other addresses should have been created by import.
      # FIXME: review how the calendar importer ingests addresses
      #   and how they should be recycled if possible.
      # assert_equal 3, Address.count

      # Were the correct number of events found at each partner location?
      assert_equal 2, Event.joins(:address).where('lower(addresses.street_address) = (?)', partner.name.downcase).count
    end
  end

  test 'does not touch calendar updated_at timestamp' do
    VCR.use_cassette(:import_test_calendar) do
      calendar_time = DateTime.new(1990, 1, 1, 12, 30, 0)
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics',
        updated_at: calendar_time
      )

      # Identify partner by partner.name == event_location.street_address
      # (Automatically created address will not match event location.)
      partner = create(:partner, name: 'Z-aRtS')

      from_date = Date.new(2018, 11, 20)
      force_import = false
      CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

      assert_equal calendar_time, calendar.updated_at, 'Importer should not touch updated at'
    end
  end
end
