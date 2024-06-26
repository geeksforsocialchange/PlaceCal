# frozen_string_literal: true

require 'test_helper'

class Admin::CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.use_cassette(:import_test_calendar) do
      @root = create(:root)
      @neighbourhood_admin = create(:neighbourhood_admin)
      @partner_admin = create(:partner_admin)

      @partner = @partner_admin.partners.first
      @neighbourhood = @partner.address.neighbourhood
      @neighbourhood_admin.neighbourhoods << @neighbourhood

      @calendar = create(:calendar, partner: @partner, place: @partner)
      @calendar.update!(last_import_at: 1.month.ago)

      @citizen = create(:user)

      host! 'admin.lvh.me'
    end
  end

  # Calendar Index
  #
  #   Show every Calendar for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root neighbourhood_admin partner_admin]) do
    get admin_calendars_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_calendars_url
    assert_redirected_to admin_root_url
  end

  # New & Create Calendar
  #
  #   Allow roots to create new Calendars
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[root neighbourhood_admin partner_admin]) do
    get new_admin_calendar_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root neighbourhood_admin partner_admin]) do
    # Factory bot doesn't allow associations in transient attributes - yet

    place = create(:place)
    partner = create(:partner)

    assert_difference('Calendar.count') do
      VCR.use_cassette(:eventbrite_events) do
        post admin_calendars_url,
             params: { calendar: attributes_for(:calendar_for_eventbrite,
                                                place_id: place.id,
                                                partner_id: partner.id) }
        assert_response :redirect
      end
    end
    assert_redirected_to edit_admin_calendar_path(assigns[:calendar])
    assert_not flash.empty?
  end

  # Edit & Update Calendar
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root neighbourhood_admin partner_admin]) do
    get edit_admin_calendar_url(@calendar)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root neighbourhood_admin partner_admin]) do
    VCR.use_cassette(:import_test_calendar) do
      patch admin_calendar_url(@calendar),
            params: { calendar: attributes_for(:calendar) }
      # Redirect to main partner screen
      assert_redirected_to edit_admin_calendar_path(@calendar)
      assert_not flash.empty?
    end
  end

  # Delete Calendar
  #
  #   Allow roots to delete all Calendars
  #   Everyone else, redirect to admin_root_url
  #
  it_allows_access_to_destroy_for(%i[root neighbourhood_admin partner_admin]) do
    assert_difference('Calendar.count', -1) do
      delete admin_calendar_url(@calendar)
    end

    assert_redirected_to admin_calendars_url
  end

  it_denies_access_to_destroy_for(%i[citizen]) do
    assert_difference('Calendar.count', 0) do
      delete admin_calendar_url(@calendar)
    end

    assert_redirected_to admin_root_url
  end

  test 'import runs importer' do
    calendar = VCR.use_cassette(:calendar_for_outlook) do
      create(:calendar,
             source: 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics',
             partner: @partner,
             place: @partner)
    end

    sign_in @root

    suppress_stdout do # The importer uses stdout to tell us progress when we run it locally. Avoid this in tests
      VCR.use_cassette('Zion Centre Guide') do
        post import_admin_calendar_path(calendar)
        assert_redirected_to edit_admin_calendar_path(calendar)
      end
    end
  end

  test 'reporting calendar notices on admin edit page' do
    calendar = VCR.use_cassette(:calendar_for_outlook) do
      create(:calendar,
             source: 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics',
             partner: @partner,
             place: @partner)
    end

    calendar.calendar_state = 'idle'
    calendar.notices = [
      'Notice 1',
      'Notice 2',
      'Notice 3'
    ]
    calendar.save!

    sign_in @root

    get edit_admin_calendar_path(calendar)
    assert_predicate response, :successful?

    assert_select 'ul#calendar-notices li', count: 3
  end

  test 'reporting calendar notices on admin show page' do
    calendar = VCR.use_cassette(:calendar_for_outlook) do
      create(:calendar,
             source: 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics',
             partner: @partner,
             place: @partner)
    end

    calendar.calendar_state = 'idle'
    calendar.notices = [
      'Notice 1',
      'Notice 2',
      'Notice 3'
    ]
    calendar.save!

    sign_in @root

    get admin_calendar_path(calendar)
    assert_predicate response, :successful?

    assert_select 'ul#calendar-notices li', count: 3
  end
end
