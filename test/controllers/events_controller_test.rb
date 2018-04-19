require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event)
  end

  test 'should get index' do
    get events_url
    assert_response :success
  end

  test 'should show event' do
    get event_url(@event)
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_superadmin_event_url
    assert_response :success
  end

  test 'superadmin: should create event' do
    event = {
      summary: 'N.A (Narcotics Anonymous)',
      place: create(:place),
      dtstart: Time.now,
      dtend:   Time.now + 2.hours
    }

    assert_difference('Event.count') do
      post superadmin_events_url, params: { event: event }
    end

    assert_redirected_to superadmin_event_url(Event.last)
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_event_url(@event)
    assert_response :success
  end

  # test 'superadmin: should update event' do
  #   patch superadmin_event_url(@event), params: { event: {  } }
  #   assert_redirected_to event_url(@event)
  # end

  test 'superadmin: should destroy event' do
    assert_difference('Event.count', -1) do
      delete superadmin_event_url(@event)
    end

    assert_redirected_to superadmin_events_url
  end
end
