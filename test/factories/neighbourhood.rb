# frozen_string_literal: true

# Each Neighbourhood is ordered by size, biggest to smallest.
# The parent neighbourhood's definition is above, the child's definition is below
FactoryBot.define do
  factory :neighbourhood_country, class: 'Neighbourhood' do
    name { 'England' }
    name_abbr { '' }
    unit { 'country' }
    unit_code_key { 'CTRY19CD' }
    unit_code_value { 'E92000001' }
    unit_name { 'England' }
  end

  factory :bare_neighbourhood, class: 'Neighbourhood' do
    name { '' }
    name_abbr { '' }
    unit { '' }
    unit_code_key { '' }
    unit_code_value { '123456789' }
    unit_name { '' }
  end

  factory :neighbourhood_region, class: 'Neighbourhood' do
    name { 'North West' }
    name_abbr { 'North West' }
    unit { 'region' }
    unit_code_key { 'RGN19CD' }
    unit_code_value { 'E12000002' }
    unit_name { 'North West' }

    after :create do |region|
      region.parent = create(:neighbourhood_country)
      region.save
    end
  end

  factory :neighbourhood_county, class: 'Neighbourhood' do
    name { 'Greater Manchester' }
    name_abbr { 'Greater Manchester' }
    unit { 'county' }
    unit_code_key { 'CTY19CD' }
    unit_code_value { 'E11000001' }
    unit_name { 'Greater Manchester' }

    after :create do |county|
      county.parent = create(:neighbourhood_region)
      county.save
    end
  end

  factory :neighbourhood_district, class: 'Neighbourhood' do
    name { 'Manchester' }
    name_abbr { 'Manchester' }
    unit { 'district' }
    unit_code_key { 'LAD19CD' }
    unit_code_value { 'E08000003' }
    unit_name { 'Manchester' }

    after :create do |district|
      district.parent = create(:neighbourhood_county)
      district.save
    end
  end

  factory :neighbourhood do
    name { 'Hulme Longname' }
    name_abbr { 'Hulme' }
    unit { 'ward' }
    unit_code_key { 'WD19CD' }
    sequence(:unit_code_value) do |n|
      "E0#{5_011_368 + n}"
    end
    unit_name { 'Hulme' }

    after :create do |ward|
      ward.parent = create(:neighbourhood_district)
      ward.save
    end
  end

  factory :rusholme_neighbourhood, class: 'Neighbourhood' do
    name { 'Rusholme' }
    name_abbr { 'Rusholme' }
    unit { 'ward' }
    unit_code_key { 'WD19CD' }
    unit_code_value { 'E05011377' }
    unit_name { 'Rusholme' }

    after :create do |ward|
      ward.parent = create(:neighbourhood_district)
      ward.save
    end
  end

  factory :moss_side_neighbourhood, class: 'Neighbourhood' do
    name { 'Moss Side' }
    name_abbr { 'Moss Side' }
    unit { 'ward' }
    unit_code_key { 'WD19CD' }
    unit_code_value { 'E05011372' }
    unit_name { 'Moss Side' }

    after :create do |ward|
      ward.parent = create(:neighbourhood_district)
      ward.save
    end
  end

  factory :ashton_neighbourhood_district, class: 'Neighbourhood' do
    name { 'Tameside' }
    name_abbr { 'Tameside' }
    unit { 'district' }
    unit_code_key { 'LAD19CD' }
    unit_code_value { 'E11000001' }
    unit_name { 'Tameside' }

    after :create do |district|
      district.parent = create(:neighbourhood_county)
      district.save
    end
  end

  factory :ashton_neighbourhood, class: 'Neighbourhood' do
    name { 'Ashton Hurst' }
    name_abbr { 'Ashton Hurst' }
    unit { 'ward' }
    unit_code_key { 'WD19CD' }
    unit_code_value { 'E05000800' }
    unit_name { 'Ashton Hurst' }

    after :create do |ward|
      ward.parent = create(:ashton_neighbourhood_district)
      ward.save
    end
  end
end
