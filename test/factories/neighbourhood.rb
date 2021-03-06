# frozen_string_literal: true

FactoryBot.define do
  factory :neighbourhood do
    name { 'Hulme Longer Name' }
    name_abbr { 'Hulme' }
    ward { 'Hulme' }
    district { 'Manchester' }
    county { 'Greater Manchester' }
    region { 'North West' }
    sequence(:WD19CD) do |n|
      "E0#{5_011_368 + n}"
    end
    WD19NM { 'Hulme' }
    LAD19CD { 'E08000003' }
    LAD19NM { 'Manchester' }
    CTY19CD { 'E11000001' }
    CTY19NM { 'Greater Manchester' }
    RGN19CD { 'E12000002' }
    RGN19NM { 'North West' }

    after(:build) { |n| n.users = [create(:user)] }
  end

  factory :ashton_neighbourhood, class: 'Neighbourhood' do
    name { 'Ashton Hurst' }
    ward { 'Ashton Hurst' }
    district { 'Tameside' }
    county { 'Greater Manchester' }
    region { 'North West' }
    sequence(:WD19CD) do |n|
      "E0#{5_000_800 + n}"
    end
    WD19NM { 'Ashton Hurst' }
    LAD19CD { 'E05000800' }
    LAD19NM { 'Tameside' }
    CTY19CD { 'E11000001' }
    CTY19NM { 'Greater Manchester' }
    RGN19CD { 'E12000002' }
    RGN19NM { 'North West' }
  end
end
