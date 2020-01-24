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
    neighbourhood
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
