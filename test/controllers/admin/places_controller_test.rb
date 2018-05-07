require 'test_helper'

class Admin::PlacesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @partner = create(:partner)
    @place = create(:place)
    @partner.places << @place
    @turf = create(:turf)
    @turf.places << @place

    @root = create(:root)
    @turf_admin = create(:user)
    @turf_admin.turfs << @turf
    @partner_admin = create(:user)
    @partner_admin.partners << @partner
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Place Index
  #
  #   Show every Place for roots
  #   Show an empty page for citizens
  #   TODO: Allow turf_admins and partner_admins to view their Places

  it_allows_access_to_index_for(%i[root]) do
    get admin_places_url
    assert_response :success
    # Returns one entry in the table
    assert_select 'tbody tr', 1
  end

  it_allows_access_to_index_for(%i[turf_admin partner_admin citizen]) do
    get admin_places_url
    assert_response :success
    # Results table is empty
    assert_select 'tbody tr', 0
  end

  # New & Create Place
  #
  #   Allow roots to create new Places
  #   Everyone else, redirect to admin_places_url
  #   TODO: Allow turf_admins and partner_admins to create new Places

  it_allows_access_to_new_for(%i[root turf_admin]) do
    get new_admin_place_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[citizen]) do
    get new_admin_place_url
    assert_response Pundit::NotAuthorizedError
  end

  it_allows_access_to_create_for(%i[root turf_admin]) do
    assert_difference('Place.count') do
      post admin_places_url,
           params: { place: { name: 'A new place' } }
    end
  end

  # Edit & Update Place
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_places_url
  #   TODO: allow turf_admins and partner_admins to edit their Places

  it_allows_access_to_edit_for(%i[root turf_admin partner_admin]) do
    get edit_admin_place_url(@place)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root turf_admin partner_admin]) do
    patch admin_place_url(@place),
          params: { place: { name: 'Updated place name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_places_url
  end

  # Delete Place
  #
  #   Allow roots to delete all Places
  #   Everyone else redirect to admin_places_url
  #   TODO: Allow turf_admin and partner_admins to delete Places

  it_allows_access_to_destroy_for(%i[root turf_admin]) do
    assert_difference('Place.count', -1) do
      delete admin_place_url(@place)
    end

    assert_redirected_to admin_places_url
  end


end
