require 'test_helper'

class CalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @calendar = calendars(:one)
  end

  test "should get index" do
    get calendars_url
    assert_response :success
  end

  test "should get new" do
    get new_calendar_url
    assert_response :success
  end

  test "should create calendar" do
    assert_difference('Calendar.count') do
      post calendars_url, params: { calendar: {  } }
    end

    assert_redirected_to calendar_url(Calendar.last)
  end

  test "should show calendar" do
    get calendar_url(@calendar)
    assert_response :success
  end

  test "should get edit" do
    get edit_calendar_url(@calendar)
    assert_response :success
  end

  test "should update calendar" do
    patch calendar_url(@calendar), params: { calendar: {  } }
    assert_redirected_to calendar_url(@calendar)
  end

  test "should destroy calendar" do
    assert_difference('Calendar.count', -1) do
      delete calendar_url(@calendar)
    end

    assert_redirected_to calendars_url
  end
end
