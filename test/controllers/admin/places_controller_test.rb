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
    @turf_admin.turfs << @turf
    @partner_admin  = create(:partner_admin)
    @partner_admin.partners << @partner

    host! 'admin.lvh.me'
  end

  # Place Index
  it_allows_access_to(%i[root turf_admin partner_admin], :index) do
    get admin_place_url
  end

  # New Place
  it_allows_access_to(%i[root turf_admin], :new) do
    get new_admin_place_url
  end

  # Create Place
  it_allows_access_to(%i[root turf_admin], :create) do
    assert_difference('Place.count') do
      post admin_place_url,
           params: { place: { name: 'A new place' } }
    end
  end

  # Delete Place
  it_allows_access_to(%i[root turf_admin], :delete) do
    assert_difference('Place.count', -1) do
      delete admin_partner_url(@place)
    end

    assert_redirected_to admin_place_url
  end

  # Edit Place
  it_allows_access_to(%i[root turf_admin partner_admin], :edit) do
    get edit_admin_place_url(@place)
  end

  # Update Place
  it_allows_access_to(%i[root turf_admin partner_admin], :patch) do
    patch admin_place_url(@place),
          params: { place: { name: 'Updated place name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_place_url
  end
end
