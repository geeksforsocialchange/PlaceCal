require 'test_helper'

class Admin::PlacesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @partner = create(:partner)
    @place = create(:place)
    @partner.places << @place
    @turf = create(:turf)
    @turf.places << @place

    @root = create(:root)
    @turf_admin = create(:turf_admin)
    @partner_admin = create(:partner_admin)
    #TODO: Consider non-admin and non-root users
    #@user = create(:user)

    host! 'admin.lvh.me'
  end

  # Place Index
  it_allows_access_to_index_for(%i[root turf_admin partner_admin]) do
    get admin_places_url
    assert_response :success
  end

  # New Place
  it_allows_access_to_new_for(%i[root turf_admin]) do
    get new_admin_place_url
    assert_response :success
  end

  # Create Place
  it_allows_access_to_create_for(%i[root turf_admin]) do
    assert_difference('Place.count') do
      post admin_places_url,
           params: { place: { name: 'A new place' } }
    end
  end

  # Edit Place
  it_allows_access_to_edit_for(%i[root turf_admin partner_admin]) do
    get edit_admin_place_url(@place)
    assert_response :success
  end

  # Update Place
  it_allows_access_to_update_for(%i[root turf_admin partner_admin]) do
    patch admin_place_url(@place),
          params: { place: { name: 'Updated place name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_places_url
  end

  # Delete Place
  it_allows_access_to_destroy_for(%i[root turf_admin]) do
    assert_difference('Place.count', -1) do
      delete admin_place_url(@place)
    end

    assert_redirected_to admin_places_url
  end


end
