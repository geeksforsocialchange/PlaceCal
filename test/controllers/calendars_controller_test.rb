require 'test_helper'

class CalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @calendar = create(:calendar)
  end

  test 'should get index' do
    get superadmin_calendars_url
    assert_response :success
  end

  test 'should show calendar' do
    get superadmin_calendar_url(@calendar)
    assert_response :success
  end

  test "superadmin: should get new" do
    get new_superadmin_calendar_url
    assert_response :success
  end

  test "superadmin: should create calendar" do
    assert_difference('Calendar.count') do
      post superadmin_calendars_url, params: { calendar: { name: 'Test Calendar' } }
    end

    assert_redirected_to superadmin_calendar_url(Calendar.last)
  end

  test "superadmin: should get edit" do
    get edit_superadmin_calendar_url(@calendar)
    assert_response :success
  end

  test "superadmin: should update calendar" do
    patch superadmin_calendar_url(@calendar), params: { calendar: { name: 'New Test Calendar Name' } }
    assert_redirected_to superadmin_calendar_url(@calendar)
  end

  test "superadmin: should destroy calendar" do
    assert_difference('Calendar.count', -1) do
      delete superadmin_calendar_url(@calendar)
    end

    assert_redirected_to superadmin_calendars_url
  end
end
