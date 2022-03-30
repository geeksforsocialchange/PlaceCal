# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  setup do
    @calendar = create(:calendar)

    @event_data = {
      dtend: DateTime.now + 1.day,
      is_active: true,
      address: create(:address),
      raw_location_from_source: \
        'Unformatted Address,' \
        'Ungeolocated Lane,' \
        'Manchester'
    }
  end

  test 'ensure validation fails for duplicate event model' do
    event_hash = { summary: 'Mom and Pops Pet Store',
                   dtstart: DateTime.now - 1.hour,
                   calendar: @calendar,
                   **@event_data
                 }

    assert Event.new(event_hash).save
    refute Event.new(event_hash).valid?

    assert_raises ActiveRecord::RecordInvalid do
      Event.new(event_hash).save!
    end
  end

  test 'can create two events with the same start date and calendar but diff summary' do
    event_hash = { dtstart: DateTime.now - 1.hour, calendar: @calendar, **@event_data }
    a = Event.new(summary: 'cycling triathalon', **event_hash)
    assert a.save

    b = Event.new(summary: 'foonlys get together :,)', **event_hash)
    assert b.valid?
  end

  test 'can create two events with the same summary and calendar but diff start' do
    event_hash = { summary: 'Harolds composure', calendar: @calendar, **@event_data }
    a = Event.new(dtstart: DateTime.now - 1.hour, **event_hash)
    assert a.save

    b = Event.new(dtstart: DateTime.now - 3.hour, **event_hash)
    assert b.valid?
  end

  test 'can create two events with the same summary and dtstart but diff calendar' do
    event_hash = { summary: 'Harolds composure', dtstart: DateTime.now - 1.hour, **@event_data }
    a = Event.new(calendar: @calendar, **event_hash)
    assert a.save

    b = Event.new(calendar: create(:calendar), **event_hash)
    assert b
  end
end
