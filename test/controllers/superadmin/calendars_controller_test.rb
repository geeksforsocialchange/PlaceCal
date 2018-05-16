# frozen_string_literal: true

require 'test_helper'

class SuperadminCalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @calendar = create(:calendar)
    @root = create(:root)
    @citizen = create(:user)

    host! 'lvh.me'
  end

  it_allows_access_to_index_for(%i[root]) do
    get superadmin_calendars_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get superadmin_calendars_url
    assert_redirected_to root_url
  end

  it_allows_access_to_show_for(%i[root]) do
    get superadmin_calendar_url(@calendar)
    assert_response :success
  end

  it_denies_access_to_show_for(%i[citizen]) do
    get superadmin_calendar_url(@calendar)
    assert_redirected_to root_url
  end

  it_allows_access_to_new_for(%i[root]) do
    get new_superadmin_calendar_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[citizen]) do
    get new_superadmin_calendar_url
    assert_redirected_to root_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Calendar.count') do
      post superadmin_calendars_url,
           params: { calendar: { name: 'Test Calendar' } }
    end
  end

  it_allows_access_to_update_for(%i[root]) do
    patch superadmin_calendar_url(@calendar),
          params: { calendar: { name: 'New Test Calendar Name' } }
    assert_redirected_to superadmin_calendar_url(@calendar)
  end

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Calendar.count', -1) do
      delete superadmin_calendar_url(@calendar)
    end
  end

  test 'redirects if not logged in' do
    get superadmin_calendars_url
    assert_redirected_to new_user_session_path
    get superadmin_calendar_url(@calendar)
    assert_redirected_to new_user_session_path
    get new_superadmin_calendar_url
    assert_redirected_to new_user_session_path
  end
end
