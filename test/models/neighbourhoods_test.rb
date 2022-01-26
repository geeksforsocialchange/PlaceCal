require 'test_helper'

class NeighbourhoodsAncestryTest < ActiveSupport::TestCase
  setup do
    @neighbourhood = create(:neighbourhood)
    @ashton_neighbourhood = create(:ashton_neighbourhood)
    # Generated from a real postcodesio response, I just stripped out everything that was unnecessary
  end

  test 'can get parents via attribute methods' do
    assert @neighbourhood.region
    assert @neighbourhood.county
    assert @neighbourhood.district
    assert @neighbourhood.country

    assert @ashton_neighbourhood.district.name == 'Tameside'
    assert @ashton_neighbourhood.district.unit == 'district'

    assert @ashton_neighbourhood.county.name == 'Greater Manchester'
    assert @ashton_neighbourhood.county.unit == 'county'

    assert @ashton_neighbourhood.region.name == 'North West'
    assert @ashton_neighbourhood.region.unit == 'region'

    assert @ashton_neighbourhood.country.name == 'England'
    assert @ashton_neighbourhood.country.unit == 'country'
  end
end
