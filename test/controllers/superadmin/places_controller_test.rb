require 'test_helper'

class Superadmin::PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
    @root = create(:root)
  end

  it_allows_root_to_access('get', :index) do
    get superadmin_places_url
  end

  it_denies_access_to_non_root('get', :index) do
    get superadmin_places_url
  end

  test 'superadmin: should get index' do
    sign_in @root
    get superadmin_places_url
    assert_response :success
  end

  test 'superadmin: should show place' do
    sign_in @root
    get superadmin_place_url(@place)
    assert_response :success
  end

  it_allows_root_to_access('get', :new) do
    get new_superadmin_place_url
  end

  it_denies_access_to_non_root('get', :new) do
    get new_superadmin_place_url
  end

  test 'superadmin: should get new' do
    sign_in @root
    get new_superadmin_place_url
    assert_response :success
  end

  test 'superadmin: should create place' do
    sign_in @root
    turf = create(:turf)
    address = create(:address)

    assert_difference('Place.count') do
      post superadmin_places_url, params: { place: attributes_for(:place, name: Faker::Company.name).merge(turf_ids: [turf.id], address_id: address.id) }
    end

    assert_redirected_to superadmin_place_url(Place.last)
  end

  test 'superadmin: should get edit' do
    sign_in @root
    get edit_superadmin_place_url(@place)
    assert_response :success
  end

  test 'superadmin: should update place' do
    sign_in @root
    patch superadmin_place_url(@place), params: { place: attributes_for(:place) }
    assert_redirected_to superadmin_place_url(@place)
  end

  test 'superadmin: should destroy place' do
    sign_in @root
    assert_difference('Place.count', -1) do
      delete superadmin_place_url(@place)
    end

    assert_redirected_to superadmin_places_url
  end
end
