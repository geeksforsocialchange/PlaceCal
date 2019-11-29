# frozen_string_literal: true

require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  setup do
    @calendar = Calendar.new
  end

  test 'has required fields' do
    # Must have a name and source URL
    @calendar.save
    refute @calendar.valid?
    @calendar.update(name: "A name for the calendar")
    refute @calendar.valid?
    @calendar.update(source: "http://my-calendar.com")
    assert @calendar.valid?

    # Sources must be unique
    @existing_calendar = create(:calendar)
    @existing_calendar.update(source: "http://my-calendar.com")
    refute @existing_calendar.valid?
    assert_equal ["Calendar source is already in use"], @existing_calendar.errors[:source]
  end

  test 'gets a contact for each calendar' do
    @calendar = Calendar.new(name: 'Test calendar', source: 'http://my-calendar.com')
  end
end
