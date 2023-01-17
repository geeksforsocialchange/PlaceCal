# frozen_string_literal: true

require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  setup do
    @calendar = Calendar.new
  end

  test 'has required fields' do
    # Must have a name and source URL

    assert_not_predicate @calendar, :valid?
    @calendar.name = 'A name for the calendar'
    assert_not_predicate @calendar, :valid?
    @calendar.source = 'https://example.com' # my-calendar.com'
    assert_not_predicate @calendar, :valid?
    @calendar.partner = create(:partner)
    assert_not_predicate @calendar, :valid?
    @calendar.place = create(:partner)
    assert_predicate @calendar, :valid?

    VCR.use_cassette(:calendar_bad_source_url) do
      @calendar.save
    end

    # Sources must be unique
    VCR.use_cassette(:import_test_calendar) do
      @existing_calendar = create(:calendar)
    end

    VCR.use_cassette(:calendar_bad_source_url) do
      @existing_calendar.update(source: 'https://example.com') # my-calendar.com')
    end

    assert_not_predicate @existing_calendar, :valid?
    assert_equal ['calendar source already in use'], @existing_calendar.errors[:source]
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
