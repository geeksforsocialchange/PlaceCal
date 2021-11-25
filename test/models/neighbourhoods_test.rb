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

    assert @ashton_neighbourhood.district.name == 'Tameside'
    assert @ashton_neighbourhood.district.unit == 'district'
  end

  test 'create from postcodesio' do
    response = {
      'postcode' => 'M15 5FS',
      'country' => 'England',
      'region' => 'North West',
      'admin_district' => 'Manchester',
      'admin_county' => nil,
      'admin_ward' => 'Hulme',
      'codes' => {
        'admin_district' => 'E08000003',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05011368'
      }
    }

    ward = Neighbourhood.create_from_postcodesio_response response

    assert ward.name == response['admin_ward']
    assert ward.unit == 'ward'
    assert ward.unit_name == response['admin_ward']
    assert ward.unit_code_key == 'WD19CD'
    assert ward.unit_code_value == response['codes']['admin_ward']

    assert ward.district.name == response['admin_district']
    assert ward.district.unit == 'district'
    assert ward.district.unit_name == response['admin_district']
    assert ward.district.unit_code_key == 'LAD19CD'
    assert ward.district.unit_code_value == response['codes']['admin_district']

    assert ward.county.name == response['admin_county']
    assert ward.county.unit == 'county'
    assert ward.county.unit_name == response['admin_county']
    assert ward.county.unit_code_key == 'CTY19CD'
    assert ward.county.unit_code_value == response['codes']['admin_county']

    assert ward.region.name == response['region']
    assert ward.region.unit == 'region'
    assert ward.region.unit_name == response['region']
    assert ward.region.unit_code_key == 'RGN19CD'
    assert ward.region.unit_code_value == ''
  end
end
