require 'test_helper'

class Admin::PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
    host! 'admin.lvh.me'
  end

  it_allows_admin_to_access('get', :index) do
    get admin_places_url
  end

  it_denies_access_to_non_admin('get', :index) do
    get admin_places_url
  end

  # No show page as we go directly to edit for now
  #
  # test 'admin: should show place' do
  #   get admin_place_url(@place)
  #   assert_response :success
  # end

  it_allows_admin_to_access('get', :new) do
    get new_admin_place_url
  end

  it_denies_access_to_non_admin('get', :new) do
    get new_admin_place_url
  end

  test 'admin: should create place' do
    sign_in create(:admin)
    assert_difference('Place.count') do
      post admin_places_url,
           params: { place: { name: 'Place Name' } }
    end
    # Redirect to the main place screen
    assert_redirected_to admin_places_url
  end

  test 'admin: should get edit' do
    sign_in create(:admin)
    get edit_admin_place_url(@place)
    assert_response :success
  end

  test 'admin: should update place' do
    sign_in create(:admin)
    patch admin_place_url(@place),
          params: { place: { name: 'Updated place name' } }
    # Redirect to main place screen
    assert_redirected_to admin_places_url
  end

  # We don't let admins delete from this screen yet
  #
  # test 'admin: should destroy place' do
  #   assert_difference('Partner.count', -1) do
  #     delete admin_place_url(@place)
  #   end
  #
  #   assert_redirected_to admin_places_url
  # end
end
