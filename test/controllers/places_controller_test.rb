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

  test 'superadmin: should get new' do
    get new_superadmin_place_url
    assert_response :success
  end

  test 'superadmin: should create place' do
    assert_difference('Place.count') do
      post superadmin_places_url, params: { place: attributes_for(:place) }
    end

    assert_redirected_to place_url(Place.last)
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_place_url(@place)
    assert_response :success
  end

  test 'superadmin: should update place' do
    patch superadmin_place_url(@place), params: { place: attributes_for(:place) }
    assert_redirected_to superadmin_place_url(@place)
  end

  test 'superadmin: should destroy place' do
    assert_difference('Place.count', -1) do
      delete superadmin_place_url(@place)
    end

    assert_redirected_to superadmin_places_url
  end
end
