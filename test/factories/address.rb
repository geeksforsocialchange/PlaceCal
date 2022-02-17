# frozen_string_literal: true

FactoryBot.define do
  factory(:address) do
    street_address { '123 Moss Ln E' }
    street_address2 { 'Manchester' }
    city { 'Manchester' }
    country_code { 'UK' }
    latitude { 53.4651064 }
    longitude { -2.2484797 }
    postcode { 'M15 5DD' }

    after :create do |address|
      parent = create(:neighbourhood_district)
      address.neighbourhood.parent = parent
      address.neighbourhood.save!
      parent.save!
    end
  end

  factory :moss_side_address, class: 'Address' do
    street_address { '42 Alexandra Rd' }
    street_address2 { 'Moss Side' }
    city { 'Manchester' }
    country_code { 'UK' }
    latitude { '53.430720' }
    longitude { '-2.436610' }
    postcode { 'M16 7BA' }

    association :neighbourhood, factory: :moss_side_neighbourhood
  end

  factory :rushholme_address, class: 'Address' do
    street_address { '31 Walmer St' }
    street_address2 { 'Rusholme' }
    city { 'Manchester' }
    country_code { 'UK' }
    latitude { '-2.227180' }
    longitude { '-2.227180' }
    postcode { 'M14 5UX' }

    association :neighbourhood, factory: :rusholme_neighbourhood
  end

  factory :ashton_address, class: 'Address' do
    street_address { 'St Damians School' }
    street_address2 { 'Ashton-under-Lyne' }
    city { 'Tameside' }
    country_code { 'UK' }
    latitude { 53.509207 }
    longitude { -2.077027 }
    postcode { 'OL6 8BH' }

    association :neighbourhood, factory: :ashton_neighbourhood
  end
end
