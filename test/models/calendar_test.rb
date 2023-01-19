# frozen_string_literal: true

require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  setup do
    @calendar = Calendar.new
  end

  test 'has required fields' do
    # Must have a name and source URL

    assert_not_predicate(@calendar, :valid?)

    errors = @calendar.errors
    assert_predicate errors[:name], :present?
    assert_equal("can't be blank", errors[:name].first)

    assert_predicate errors[:source], :present?
    assert_equal(["can't be blank", 'not a valid URL'], errors[:source])

    assert_predicate errors[:partner], :present?
    assert_equal("can't be blank", errors[:partner].first)

    assert_predicate errors[:place], :present?
    assert_equal("can't be blank with this strategy", errors[:place].first)

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
end
