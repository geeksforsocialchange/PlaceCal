require 'test_helper'

class SuperadminEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event)
  end

  test 'superadmin: should get index' do
    get superadmin_events_url
    assert_response :success
  end

  test 'superadmin: should show event' do
    get superadmin_event_url(@event)
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_superadmin_event_url
    assert_response :success
  end

  test 'superadmin: should create event' do
    assert_difference('Event.count') do
      post superadmin_events_url, params: { event: attributes_for(:event) }
    end

    assert_redirected_to superadmin_event_url(Event.last)
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_event_url(@event)
    assert_response :success
  end

  test 'superadmin: should update event' do
    patch superadmin_event_url(@event), params: { event: attributes_for(:event) }
    assert_redirected_to superadmin_event_url(@event)
  end

  test 'superadmin: should destroy event' do
    assert_difference('Event.count', -1) do
      delete superadmin_event_url(@event)
    end

    assert_redirected_to superadmin_events_url
  end
end
