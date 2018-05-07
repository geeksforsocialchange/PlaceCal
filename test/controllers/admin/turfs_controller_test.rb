require 'test_helper'

class Admin::TurfsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @turf = create(:turf)
    @root = create(:root)
    @turf_admin = create(:user)
    @turf_admin.turfs << @turf
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Turf Index
  it_allows_access_to_index_for(%i[root turf_admin]) do
    get admin_turfs_url
    assert_response :success
  end

  # New Turf
  it_allows_access_to_new_for(%i[root]) do
    get new_admin_turf_url
    assert_response :success
  end

  # Create Turf
  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Turf.count') do
      post admin_turfs_url,
        params: { turf: attributes_for(:turf) }
    end
  end

  # Edit Turf
  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_turf_url(@turf)
    assert_response :success
  end

  # Update Turf
  it_allows_access_to_update_for(%i[root]) do
    patch admin_turf_url(@turf),
      params: { turf: attributes_for(:turf) }
    # Redirect to main partner screen
    assert_redirected_to admin_turfs_url
  end

  # Delete Turf
  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Turf.count', -1) do
      delete admin_turf_url(@turf)
    end

    assert_redirected_to admin_turfs_url
  end


end
