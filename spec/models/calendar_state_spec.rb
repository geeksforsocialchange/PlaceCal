# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Calendar do
  include ActiveJob::TestHelper

  let(:source_url) { 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics' }

  describe 'calendar_state' do
    it 'is idle by default' do
      expect(Calendar.new.calendar_state).to be_idle
    end
  end

  describe '#queue_for_import!' do
    it 'can be pushed into queue' do
      VCR.use_cassette(:import_test_calendar) do
        expect {
          calendar = create(:calendar, notices: %w[one two three])
          calendar.queue_for_import!(false, Date.new(2000, 1, 1))
          expect(calendar.calendar_state).to be_in_queue
          # clears notices
          expect(calendar.notices).to be_nil
        }.to have_enqueued_job.exactly(1)
      end
    end

    it 'cannot be queued if not idle' do
      VCR.use_cassette(:import_test_calendar) do
        expect {
          calendar = create(:calendar, calendar_state: :in_queue)
          calendar.queue_for_import!(false, Date.new(2000, 1, 1))
          expect(calendar.calendar_state).to be_in_queue
        }.not_to have_enqueued_job
      end
    end
  end

  describe '#flag_start_import_job!' do
    it 'can move into working state' do
      VCR.use_cassette(:import_test_calendar) do
        calendar = create(:calendar, calendar_state: :in_queue, source: source_url, notices: %w[one two three])
        calendar.flag_start_import_job!
        expect(calendar.calendar_state).to be_in_worker
        # clears notices
        expect(calendar.notices).to be_nil
      end
    end
  end

  describe '#flag_complete_import_job!' do
    it 'can move into idle state' do
      VCR.use_cassette(:import_test_calendar) do
        calendar = create(:calendar, calendar_state: :in_worker, source: source_url)
        calendar.flag_complete_import_job!([], 'ical')
        expect(calendar.calendar_state).to be_idle
        expect(calendar.last_import_at.to_i).to be_within(24.hours).of(Time.now.to_i)
      end
    end
  end

  describe '#flag_error_import_job!' do
    it 'can move into error state' do
      VCR.use_cassette(:import_test_calendar) do
        bad_message = 'A description of the error'
        calendar = create(:calendar, calendar_state: :in_worker, source: source_url)
        calendar.flag_error_import_job!(bad_message)
        expect(calendar.calendar_state).to be_error
        expect(calendar.critical_error).to eq(bad_message)
      end
    end

    it 'can move into error state even if calendar is invalid' do
      VCR.use_cassette(:import_test_calendar) do
        bad_message = 'A description of the error'
        name = 'Calendar name'
        calendar = create(:calendar, calendar_state: :in_worker, source: source_url, name: name)

        # build some duplicate events
        event_args = {
          dtstart: Date.new,
          summary: 'This is a summary',
          calendar_id: calendar.id
        }
        calendar.events.build(event_args)
        calendar.events.build(event_args)

        # set some invalid state
        calendar.name = nil
        expect(calendar).to be_invalid

        # flag bad thing
        calendar.flag_error_import_job!(bad_message)

        # check the calendar is back to how it was
        expect(calendar.name).to eq(name)
        expect(calendar).to be_valid

        # check the error was saved to calendar
        expect(calendar.calendar_state).to be_error
        expect(calendar.critical_error).to eq(bad_message)
      end
    end
  end

  describe 'error state' do
    it 'can be tested for' do
      VCR.use_cassette(:import_test_calendar) do
        calendar = create(:calendar)
        calendar.calendar_state = :error
        expect(calendar.calendar_state).to be_error
      end
    end
  end

  describe '#flag_bad_source!' do
    it 'can move from in_worker to bad_source' do
      VCR.use_cassette(:import_test_calendar) do
        calendar = create(:calendar, calendar_state: :in_worker)
        calendar.events << Event.new(dtstart: 'today') # is invalid

        calendar.flag_bad_source!('Failed to read from source URL')

        calendar.reload
        expect(calendar.calendar_state).to eq('bad_source')
        expect(calendar.critical_error).to eq('Failed to read from source URL')
      end
    end
  end
end
