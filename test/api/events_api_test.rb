require 'test_helper'

class PlaceCal::APITest < ActiveSupport::TestCase
  include Rack::Test::Methods

  # setup do
  #
  # end

  def app
    Rails.application
  end

  test 'GET /api/v1/events returns an array of valid events' do
    # Test a bunch of different combos
    create(:event, :with_place, :with_partner)
    create(:event, :with_partner)
    create(:event, :with_place)
    create(:event)
    get '/api/v1/events'
    assert last_response.ok?
    response = JSON.parse(last_response.body)
    assert_equal 4, response.length
    response.each do |event|
      assert_matches_json_schema event, 'event'
    end
  end

  test 'GET /api/v1/events/:id returns an event' do
    event = create(:event)
    get "/api/v1/events/#{event.id}"
    assert last_response.ok?
    response = JSON.parse(last_response.body)
    assert_matches_json_schema response, 'event'
  end

  test 'GET /api/v1/events/:id returns 404 if the event does not exist' do
    get "/api/v1/events/123456789"
    assert last_response.status == 404
    response = JSON.parse(last_response.body)
    assert response.has_key?('error')
  end
end
