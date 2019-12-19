# frozen_string_literal: true

require 'test_helper'

class Admin::NeighbourhoodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @neighbourhood = @neighbourhood_admin.neighbourhoods.first
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Neighbourhood Index
  #
  #   Show every Neighbourhood for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_neighbourhoods_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[neighbourhood_admin citizen]) do
    get admin_neighbourhoods_url
    assert_redirected_to admin_root_url
  end

  # New & Create Neighbourhood
  #
  #   Noone can create these manually.
  #   They get created automatically when new addresses are detected.

  it_denies_access_to_new_for(%i[root neighbourhood_admin citizen]) do
    get new_admin_neighbourhood_url
    assert_redirected_to admin_root_url
  end

  # Edit & Update Neighbourhood
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_neighbourhood_url(@neighbourhood)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_neighbourhood_url(@neighbourhood),
          params: { neighbourhood: attributes_for(:neighbourhood) }
    # Redirect to main partner screen
    assert_redirected_to admin_neighbourhoods_url
  end

  it_denies_access_to_edit_for(%i[neighbourhood_admin citizen]) do
    get edit_admin_neighbourhood_url(@neighbourhood)
    assert_redirected_to admin_root_url
  end

  # Delete Neighbourhood
  #
  #   Allow roots to delete all Neighbourhoods
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Neighbourhood.count', -1) do
      delete admin_neighbourhood_url(@neighbourhood)
    end

    assert_redirected_to admin_neighbourhoods_url
  end
end
