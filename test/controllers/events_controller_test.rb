require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event)
  end

  test 'should get index' do
    get events_url
    assert_response :success
    assert_template 'index'
  end

  test 'should get simple html index' do
    get events_url, params: { simple: true }
    assert_response :success
    assert_template 'index_simple'
  end

  test 'should get plain text index' do
    get '/events.text'
    assert_response :success
    assert_equal 'text/plain', response.content_type
  end

  test 'should show event' do
    get event_url(@event)
    assert_response :success
  end
end
