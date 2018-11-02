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
  end
end
