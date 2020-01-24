# frozen_string_literal: true

require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  setup do
    @calendar = Calendar.new
  end

  test 'has required fields' do
    # Must have a name and source URL

    refute @calendar.valid?
    @calendar.name = "A name for the calendar"
    refute @calendar.valid?
    @calendar.source = "https://my-calendar.com"
    refute @calendar.valid?
    @calendar.partner = create(:partner)
    refute @calendar.valid?
    @calendar.place = create(:partner)
    assert @calendar.valid?
    @calendar.save
    # Sources must be unique
    @existing_calendar = create(:calendar)
    @existing_calendar.update(source: "https://my-calendar.com")
    refute @existing_calendar.valid?
    assert_equal ["calendar source already in use"], @existing_calendar.errors[:source]
  end

  test 'gets a contact for each calendar' do
    @calendar = create(:calendar)
    assert @calendar.valid?
    # If calendar contact listed, show that
    assert_equal [ @calendar.public_contact_email,
                   @calendar.public_contact_name
                 ], @calendar.contact_information
    # Otherwise, show the partner public contact if possible
    @calendar.update(public_contact_email: nil)
    assert_equal [ @calendar.partner.public_email,
                   @calendar.partner.public_name
                 ], @calendar.contact_information
    # Otherwise, show the default location contact if possible
    @calendar.partner.update(public_email: nil)
    assert_equal [ @calendar.place.public_email,
                   @calendar.place.public_name
                 ], @calendar.contact_information
    # Otherwise, return false
    @calendar.place.update(public_email: nil)
    assert_equal false, @calendar.contact_information
  end
end
