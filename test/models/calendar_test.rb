# frozen_string_literal: true

require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  setup do
    @calendar = Calendar.new
  end

  test 'has required fields' do
    # Must have a name and source URL

    VCR.use_cassette(:example_dot_com_bad_response, allow_playback_repeats: true) do
      assert_not_predicate(@calendar, :valid?)

      errors = @calendar.errors
      assert_predicate errors[:name], :present?
      assert_equal("can't be blank", errors[:name].first)

      # testing for presence
      assert_predicate errors[:source], :present?
      assert_equal(["can't be blank", 'not a valid URL'], errors[:source])

      assert_predicate errors[:partner], :present?
      assert_equal("can't be blank", errors[:partner].first)

      assert_predicate errors[:place], :present?
      assert_equal("can't be blank with this strategy", errors[:place].first)

      @calendar.source = 'https://example.com/'
      assert_not_predicate(@calendar, :valid?)

      # testing for bad source
      assert_predicate errors[:source], :present?
      assert_equal('The source URL returned an invalid code (The source URL could not be read (code=401))', errors[:source].first)
    end

    # make valid
    partner = create(:partner)
    @calendar.name = 'Calendar Name'
    @calendar.partner = partner
    @calendar.place = partner
    @calendar.source = 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'

    VCR.use_cassette(:import_test_calendar) do
      assert_predicate @calendar, :valid?
    end
  end

  test 'source must be unique' do
    VCR.use_cassette(:import_test_calendar) do
      first_calendar = create(:calendar)
      assert_predicate first_calendar, :valid?

      second_calendar = build(:calendar)
      assert_not_predicate(second_calendar, :valid?)

      message = second_calendar.errors[:source]&.first
      assert_equal('calendar source already in use', message)
    end
  end

  test 'source only validated if it has changed' do
    calendar = VCR.use_cassette(:import_test_calendar) do
      create :calendar
    end

    assert_predicate calendar, :valid? # this is a noop in this context

    calendar.name = 'A different name'
    assert_predicate calendar, :valid? # does not need VCR cassette

    VCR.use_cassette(:eventbrite_events) do
      calendar.source = 'https://www.eventbrite.co.uk/o/ftm-london-32888898939'
      assert_predicate calendar, :valid? # source changed, will validate URL reachable
    end
  end

  test 'gets a contact for each calendar' do
    VCR.use_cassette(:import_test_calendar) do
      @calendar = create(:calendar)
    end

    assert_predicate @calendar, :valid?
    # If calendar contact listed, show that
    assert_equal [@calendar.public_contact_email,
                  @calendar.public_contact_name], @calendar.contact_information
    # Otherwise, show the partner public contact if possible
    @calendar.update(public_contact_email: nil)
    assert_equal [@calendar.partner.public_email,
                  @calendar.partner.public_name], @calendar.contact_information
    # Otherwise, show the default location contact if possible
    @calendar.partner.update(public_email: nil)
    assert_equal [@calendar.place.public_email,
                  @calendar.place.public_name], @calendar.contact_information
    # Otherwise, return false
    @calendar.place.update(public_email: nil)
    assert_not @calendar.contact_information
  end

  test 'notices get counted when saved' do
    VCR.use_cassette(:import_test_calendar) do
      messages = %w[
        alpha
        beta
        cappa
      ]

      calendar = build(:calendar)
      calendar.notices = messages
      calendar.save!

      assert_equal 3, calendar.notice_count
    end
  end

  test 'notices are not counted if notices have not changed value' do
    VCR.use_cassette(:import_test_calendar) do
      messages = %w[
        alpha
        beta
        cappa
      ]

      calendar = create(:calendar, notices: messages)

      calendar.name = 'A new name'
      calendar.save!

      assert_equal 3, calendar.notice_count
    end
  end

  test 'updating calendar state does not touch updated_at' do
    VCR.use_cassette(:import_test_calendar) do
      today = Date.new(1990, 1, 1)
      calendar = create(:calendar, updated_at: today)
      assert_equal today, calendar.updated_at

      # queue_for_import
      calendar.queue_for_import! false, today
      assert_equal today, calendar.updated_at

      # flag_start_import_job
      calendar.calendar_state = :in_queue
      calendar.flag_start_import_job!
      assert_equal today, calendar.updated_at

      # flag_complete_import_job
      calendar.calendar_state = :in_worker
      calendar.flag_complete_import_job! [], 123_456, 'null'
      assert_equal today, calendar.updated_at

      # flag_bad_source
      calendar.calendar_state = :in_worker
      calendar.flag_bad_source! 'problem with source'
      assert_equal today, calendar.updated_at

      # flag_error_import_job
      calendar.calendar_state = :in_worker
      calendar.flag_error_import_job! 'a problem with the import job'
      assert_equal today, calendar.updated_at
    end
  end

  test 'it shows helpful message if source URL not recognised' do
    VCR.use_cassette(:unsupported_url, allow_playback_repeats: true) do
      calendar = Calendar.new
      calendar.source = 'https://raw.githubusercontent.com/geeksforsocialchange/PlaceCal/main/config/database.yml'

      # this will only work when calendar is in 'auto' mode
      assert_not calendar.valid?
      assert_equal ['Unable to autodetect calendar format, please pick an option from the list below'], calendar.errors[:source]
    end
  end
end
