require 'test_helper'

class Superadmin::PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
  end

  test 'superadmin: should get index' do
    get superadmin_places_url
    assert_response :success
  end

  test 'superadmin: should show place' do
    get superadmin_place_url(@place)
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_superadmin_place_url
    assert_response :success
  end

  test 'superadmin: should create place' do
    turf = create(:turf)
    address = create(:address)

    assert_difference('Place.count') do
      post superadmin_places_url, params: { place: attributes_for(:place, name: Faker::Company.name).merge(turf_ids: [turf.id], address_id: address.id) }
    end

    assert_redirected_to superadmin_place_url(Place.last)
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
