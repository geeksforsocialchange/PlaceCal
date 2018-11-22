require 'test_helper'

class PlaceCal::APITest < ActiveSupport::TestCase
  include Rack::Test::Methods

  # setup do
  #
  # end

  def app
    Rails.application
  end

  test 'GET /api/v1/events returns an array of events' do
    create_list(:event, 10)
    get '/api/v1/events'
    assert last_response.ok?
    response = JSON.parse(last_response.body)
    # assert_equal 10, response.length
    assert_matches_json_schema response[0], 'event'
  end

  # test 'GET /api/placecal/:id returns a status by id' do
  #   status = Status.create!
  #   get "/api/placecal/#{status.id}"
  #   assert_equal status.to_json, last_response.body
  # end
end
