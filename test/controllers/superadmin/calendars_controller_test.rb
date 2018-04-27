require 'test_helper'

class SuperadminCalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @calendar = create(:calendar)
    @root = create(:root)
  end

  it_allows_root_to_access('get', :index) do
    get superadmin_calendars_url
  end

  it_denies_access_to_non_root('get', :index) do
    get superadmin_calendars_url
  end

  test 'superadmin: should get index' do
    sign_in @root
    get superadmin_calendars_url
    assert_response :success
  end

  test 'superadmin: should show calendar' do
    sign_in @root
    get superadmin_calendar_url(@calendar)
    assert_response :success
  end

  it_allows_root_to_access('get', :new) do
    get new_superadmin_calendar_url
  end

  it_denies_access_to_non_root('get', :new) do
    get new_superadmin_calendar_url
  end

  test 'superadmin: should get new' do
    sign_in @root
    get new_superadmin_calendar_url
    assert_response :success
  end

  test 'superadmin: should create calendar' do
    sign_in @root
    assert_difference('Calendar.count') do
      post superadmin_calendars_url,
           params: { calendar: { name: 'Test Calendar' } }
    end

    assert_redirected_to superadmin_calendar_url(Calendar.last)
  end

  test 'superadmin: should get edit' do
    sign_in @root
    get edit_superadmin_calendar_url(@calendar)
    assert_response :success
  end

  test 'superadmin: should update calendar' do
    sign_in @root
    patch superadmin_calendar_url(@calendar),
          params: { calendar: { name: 'New Test Calendar Name' } }
    assert_redirected_to superadmin_calendar_url(@calendar)
  end

  test 'superadmin: should destroy calendar' do
    sign_in @root
    assert_difference('Calendar.count', -1) do
      delete superadmin_calendar_url(@calendar)
    end

    assert_redirected_to superadmin_calendars_url
  end
end
