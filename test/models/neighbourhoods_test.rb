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
  end
end
