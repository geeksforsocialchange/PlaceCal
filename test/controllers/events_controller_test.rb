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
end
