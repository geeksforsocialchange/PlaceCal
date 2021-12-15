# frozen_string_literal: true

require 'test_helper'

class NeighbourhoodPolicyTest < ActiveSupport::TestCase
  setup do
    @citizen = create(:citizen)
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @neighbourhood_region_admin = create(:neighbourhood_region_admin)
  end

  def test_scope
    assert_equal(permitted_records(@citizen, Neighbourhood), [])
    assert_equal(permitted_records(@neighbourhood_admin, Neighbourhood), @neighbourhood_admin.neighbourhoods)
    # Enforcing ordering is annoying, just compare the length, let the user test ensure that owned_neighbourhoods works
    assert_equal(permitted_records(@neighbourhood_region_admin, Neighbourhood).length,
                 @neighbourhood_region_admin.owned_neighbourhoods.length)
    assert_equal(permitted_records(@root, Neighbourhood).length,
                 Neighbourhood.all.length)
  end
end
