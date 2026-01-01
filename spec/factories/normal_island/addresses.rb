# frozen_string_literal: true

require_relative '../../../lib/normal_island'

FactoryBot.define do
  factory :address, aliases: [:bare_address_1] do
    street_address { Faker::Address.street_address }
    postcode { 'ZZMB 1RS' }
    latitude { 53.5 }
    longitude { -1.5 }
    association :neighbourhood, factory: :riverside_ward

    # Skip geocode validation in tests (neighbourhood is already set)
    after(:build) do |address|
      address.define_singleton_method(:geocode_with_ward) { true }
    end

    # Normal Island addresses
    factory :riverside_address do
      street_address { NormalIsland::ADDRESSES[:riverside][:street_address] }
      postcode { NormalIsland::ADDRESSES[:riverside][:postcode] }
      latitude { NormalIsland::ADDRESSES[:riverside][:latitude] }
      longitude { NormalIsland::ADDRESSES[:riverside][:longitude] }
      association :neighbourhood, factory: :riverside_ward
    end

    factory :oldtown_address do
      street_address { NormalIsland::ADDRESSES[:oldtown][:street_address] }
      postcode { NormalIsland::ADDRESSES[:oldtown][:postcode] }
      latitude { NormalIsland::ADDRESSES[:oldtown][:latitude] }
      longitude { NormalIsland::ADDRESSES[:oldtown][:longitude] }
      association :neighbourhood, factory: :oldtown_ward
    end

    factory :greenfield_address do
      street_address { NormalIsland::ADDRESSES[:greenfield][:street_address] }
      postcode { NormalIsland::ADDRESSES[:greenfield][:postcode] }
      latitude { NormalIsland::ADDRESSES[:greenfield][:latitude] }
      longitude { NormalIsland::ADDRESSES[:greenfield][:longitude] }
      association :neighbourhood, factory: :greenfield_ward
    end

    factory :harbourside_address do
      street_address { NormalIsland::ADDRESSES[:harbourside][:street_address] }
      postcode { NormalIsland::ADDRESSES[:harbourside][:postcode] }
      latitude { NormalIsland::ADDRESSES[:harbourside][:latitude] }
      longitude { NormalIsland::ADDRESSES[:harbourside][:longitude] }
      association :neighbourhood, factory: :harbourside_ward
    end

    factory :hillcrest_address do
      street_address { NormalIsland::ADDRESSES[:hillcrest][:street_address] }
      postcode { NormalIsland::ADDRESSES[:hillcrest][:postcode] }
      latitude { NormalIsland::ADDRESSES[:hillcrest][:latitude] }
      longitude { NormalIsland::ADDRESSES[:hillcrest][:longitude] }
      association :neighbourhood, factory: :hillcrest_ward
    end

    factory :valleyview_address do
      street_address { NormalIsland::ADDRESSES[:valleyview][:street_address] }
      postcode { NormalIsland::ADDRESSES[:valleyview][:postcode] }
      latitude { NormalIsland::ADDRESSES[:valleyview][:latitude] }
      longitude { NormalIsland::ADDRESSES[:valleyview][:longitude] }
      association :neighbourhood, factory: :valleyview_ward
    end

    factory :cliffside_address do
      street_address { NormalIsland::ADDRESSES[:cliffside][:street_address] }
      postcode { NormalIsland::ADDRESSES[:cliffside][:postcode] }
      latitude { NormalIsland::ADDRESSES[:cliffside][:latitude] }
      longitude { NormalIsland::ADDRESSES[:cliffside][:longitude] }
      association :neighbourhood, factory: :cliffside_ward
    end

    factory :beachfront_address do
      street_address { NormalIsland::ADDRESSES[:beachfront][:street_address] }
      postcode { NormalIsland::ADDRESSES[:beachfront][:postcode] }
      latitude { NormalIsland::ADDRESSES[:beachfront][:latitude] }
      longitude { NormalIsland::ADDRESSES[:beachfront][:longitude] }
      association :neighbourhood, factory: :beachfront_ward
    end
  end
end
