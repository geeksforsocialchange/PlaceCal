# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  setup do
    @calendar = create(:calendar)
  end

  test 'ensure validation fails for duplicate event model' do
    assert_raises ActiveRecord::RecordInvalid do
      create_list(:event, 2,
                  summary: 'Mom and Pops Pet Store',
                  dtstart: DateTime.now - 1.hour,
                  calendar: @calendar)
    end
  end

  test 'can create two events with the same start date and calendar but diff summary' do
    event_hash = { dtstart: DateTime.now - 1.hour, calendar: @calendar }
    a = create(:event, summary: 'cycling triathalon', **event_hash)
    b = create(:event, summary: 'foonlys get together :,)', **event_hash)
    assert a
    assert b
  end

  test 'can create two events with the same summary and calendar but diff start' do
    event_hash = { summary: 'Harolds composure', calendar: @calendar }
    a = create(:event, dtstart: DateTime.now - 1.hour, **event_hash)
    b = create(:event, dtstart: DateTime.now - 3.hour, **event_hash)
    assert a
    assert b
  end

  test 'can create two events with the same summary and dtstart but diff calendar' do
    event_hash = { summary: 'Harolds composure', dtstart: DateTime.now - 1.hour }
    a = create(:event, calendar: @calendar, **event_hash)
    b = create(:event, calendar: create(:calendar), **event_hash)
    assert a
    assert b
  end
end
