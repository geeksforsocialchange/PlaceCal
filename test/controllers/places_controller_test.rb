# frozen_string_literal: true

require 'test_helper'

class PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
  end

  test 'should get index' do
    get places_url
    assert_response :success
  end

  test 'should show place' do
    get place_url(@place)
    assert_response :success
  end
end
