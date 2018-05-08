require 'test_helper'

class Superadmin::PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
    @root = create(:root)
  end

  it_allows_access_to_index_for(%i[root]) do
    get superadmin_places_url
  end

  it_allows_access_to_show_for(%i[root]) do
    get superadmin_place_url(@place)
  end

  it_allows_access_to_new_for(%i[root]) do
    get new_superadmin_place_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Place.count') do
      post superadmin_places_url,
        params: { place: { name: 'Test Place' } }
    end
  end

  it_allows_access_to_update_for(%i[root]) do
    patch superadmin_place_url(@place),
      params: { place: { name: 'New Test Place Name' } }
  end

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Place.count', -1) do
      delete superadmin_place_url(@place)
    end
  end
end
