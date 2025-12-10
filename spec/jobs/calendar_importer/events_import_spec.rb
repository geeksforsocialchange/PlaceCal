# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events import' do
  it 'imports webcal calendars' do
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
      expect(Event.count).to eq(11)

      # Were the correct number of events found at each partner location?
      expect(Event.joins(:address).where('lower(addresses.street_address) = (?)', partner.name.downcase).count).to eq(2)
    end
  end

  it 'does not touch calendar updated_at timestamp' do
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
      create(:partner, name: 'Z-aRtS')

      from_date = Date.new(2018, 11, 20)
      force_import = false
      CalendarImporter::CalendarImporterTask.new(calendar, from_date, force_import).run

      expect(calendar.updated_at).to eq(calendar_time)
    end
  end
end
