require 'test_helper'

class AdminPlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
    host! 'admin.lvh.me'
  end

  test 'admin: should get index' do
    sign_in create(:admin)
    get admin_places_url
    assert_response :success
  end

  test "admin: non-admins can't access index" do
    sign_in create(:user)
    get admin_places_url
    assert_redirected_to admin_root_path
  end

  # No show page as we go directly to edit for now
  #
  # test 'admin: should show place' do
  #   get admin_place_url(@place)
  #   assert_response :success
  # end

  test 'admin: should get new' do
    sign_in create(:admin)
    get new_admin_place_url
    assert_response :success
  end

  test "admin: non-admins can't access new" do
    sign_in create(:user)
    get admin_places_url
    assert_redirected_to admin_root_path
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
