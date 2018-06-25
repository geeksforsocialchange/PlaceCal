# frozen_string_literal: true

FactoryBot.define do
  factory(:place) do
    sequence(:name) do |n|
      "Zion Center #{n}"
    end
    short_description 'A description of this Place'
    email 'place@placecal.org'
    phone '0161 0000000'
    address
    url 'http://example.com'
    after(:build) do |place|
      place.turfs << FactoryBot.create(:turf)
    end
  end
end
