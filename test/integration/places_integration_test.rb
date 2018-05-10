require 'test_helper'

class PlacesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @place = create(:place)
  end

  test "should show basic information" do
    get place_url(@place)
    assert_select 'h1', @place.name
    assert_select 'p', @place.short_description
    assert_select 'p', /123 Moss Ln E/
    assert_select 'p', /Manchester/
    assert_select 'p', /M15 5DD/
  end
end
