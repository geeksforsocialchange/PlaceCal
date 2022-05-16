# frozen_string_literal: true

require 'test_helper'

class CalendarStateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  SOURCE_URL = 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'

  # idle
  test 'is idle by default' do
    assert Calendar.new.calendar_state.idle?
  end

  # queueing
  test 'can be pushed into queue' do
    assert_enqueued_jobs 0
    calendar = create(:calendar)
    calendar.queue_for_import! false, Date.new(2000, 1, 1)
    assert calendar.calendar_state.in_queue?
    assert_enqueued_jobs 1
  end

  test 'cannot be queued if not idle' do
    assert_enqueued_jobs 0
    calendar = create(:calendar, calendar_state: :in_queue)
    calendar.queue_for_import! false, Date.new(2000, 1, 1)

    # this has not changed
    assert calendar.calendar_state.in_queue?

    # not in queue
    assert_enqueued_jobs 0
  end

  test "can move into working state" do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(:calendar, calendar_state: :in_queue, source: SOURCE_URL)
      calendar.flag_start_import_job!
      assert calendar.calendar_state.in_worker?
    end
  end

  # in worker
  test "can move into idle state" do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(:calendar, calendar_state: :in_worker, source: SOURCE_URL)
      calendar.flag_complete_import_job! [], 0
      assert calendar.calendar_state.idle?
      # are we close enough?
      # deal with weird database encoding serialisations
      assert_in_delta Time.now.to_i, calendar.last_import_at.to_i, 24.hours
    end
  end

  test "can move into error state" do
    VCR.use_cassette(:import_test_calendar) do
      bad_message = 'A description of the error'
      calendar = create(:calendar, calendar_state: :in_worker, source: SOURCE_URL)
      calendar.flag_error_import_job! bad_message
      assert calendar.calendar_state.error?
      assert_equal bad_message, calendar.critical_error
    end
  end

  # error'd
  test "can be tested for" do
    calendar = create(:calendar, calendar_state: :error)
    assert calendar.calendar_state.error?
  end

end