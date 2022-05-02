# frozen_string_literal: true

require 'test_helper'

class Admin::CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partner_admin = create(:partner_admin)

    @partner = @partner_admin.partners.first
    @neighbourhood = @partner.address.neighbourhood
    @neighbourhood_admin.neighbourhoods << @neighbourhood
    @calendar = create(:calendar, partner: @partner, place: @partner)
    @citizen = create(:user)

    host! 'admin.lvh.me'
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
      post admin_calendars_url,
        params: { calendar: attributes_for(:calendar,
                                           place_id: place.id,
                                           partner_id: partner.id) }
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
    patch admin_calendar_url(@calendar),
          params: { calendar: attributes_for(:calendar) }
    # Redirect to main partner screen
    assert_redirected_to edit_admin_calendar_path(@calendar)
    assert_not flash.empty?
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

  test "import runs importer" do
    sign_in @root

    post import_admin_calendar_path(@calendar), params: { starting_from: Date.today }
    assert_redirected_to edit_admin_calendar_path(@calendar)
  end
end
