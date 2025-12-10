# frozen_string_literal: true

require_relative '../../../lib/normal_island'

FactoryBot.define do
  # Base neighbourhood factory
  factory :neighbourhood do
    sequence(:name) { |n| "Neighbourhood #{n}" }
    unit { 'ward' }
    unit_code_key { 'NO00WD' }
    sequence(:unit_code_value) { |n| "NO400000#{n}" }

    # Country level
    factory :normal_island_country do
      name { NormalIsland::COUNTRY[:name] }
      unit { NormalIsland::COUNTRY[:unit] }
      unit_code_key { NormalIsland::COUNTRY[:unit_code_key] }
      unit_code_value { NormalIsland::COUNTRY[:unit_code_value] }
    end

    # Regions
    factory :northvale_region do
      name { NormalIsland::REGIONS[:northvale][:name] }
      unit { NormalIsland::REGIONS[:northvale][:unit] }
      unit_code_key { NormalIsland::REGIONS[:northvale][:unit_code_key] }
      unit_code_value { NormalIsland::REGIONS[:northvale][:unit_code_value] }
      association :parent, factory: :normal_island_country
    end

    factory :southmere_region do
      name { NormalIsland::REGIONS[:southmere][:name] }
      unit { NormalIsland::REGIONS[:southmere][:unit] }
      unit_code_key { NormalIsland::REGIONS[:southmere][:unit_code_key] }
      unit_code_value { NormalIsland::REGIONS[:southmere][:unit_code_value] }
      association :parent, factory: :normal_island_country
    end

    # Counties
    factory :greater_millbrook_county do
      name { NormalIsland::COUNTIES[:greater_millbrook][:name] }
      unit { NormalIsland::COUNTIES[:greater_millbrook][:unit] }
      unit_code_key { NormalIsland::COUNTIES[:greater_millbrook][:unit_code_key] }
      unit_code_value { NormalIsland::COUNTIES[:greater_millbrook][:unit_code_value] }
      association :parent, factory: :northvale_region
    end

    factory :coastshire_county do
      name { NormalIsland::COUNTIES[:coastshire][:name] }
      unit { NormalIsland::COUNTIES[:coastshire][:unit] }
      unit_code_key { NormalIsland::COUNTIES[:coastshire][:unit_code_key] }
      unit_code_value { NormalIsland::COUNTIES[:coastshire][:unit_code_value] }
      association :parent, factory: :southmere_region
    end

    # Districts
    factory :millbrook_district do
      name { NormalIsland::DISTRICTS[:millbrook][:name] }
      unit { NormalIsland::DISTRICTS[:millbrook][:unit] }
      unit_code_key { NormalIsland::DISTRICTS[:millbrook][:unit_code_key] }
      unit_code_value { NormalIsland::DISTRICTS[:millbrook][:unit_code_value] }
      association :parent, factory: :greater_millbrook_county
    end

    factory :ashdale_district do
      name { NormalIsland::DISTRICTS[:ashdale][:name] }
      unit { NormalIsland::DISTRICTS[:ashdale][:unit] }
      unit_code_key { NormalIsland::DISTRICTS[:ashdale][:unit_code_key] }
      unit_code_value { NormalIsland::DISTRICTS[:ashdale][:unit_code_value] }
      association :parent, factory: :greater_millbrook_county
    end

    factory :seaview_district do
      name { NormalIsland::DISTRICTS[:seaview][:name] }
      unit { NormalIsland::DISTRICTS[:seaview][:unit] }
      unit_code_key { NormalIsland::DISTRICTS[:seaview][:unit_code_key] }
      unit_code_value { NormalIsland::DISTRICTS[:seaview][:unit_code_value] }
      association :parent, factory: :coastshire_county
    end

    # Wards - Millbrook District
    factory :riverside_ward do
      name { NormalIsland::WARDS[:riverside][:name] }
      unit { NormalIsland::WARDS[:riverside][:unit] }
      unit_code_key { NormalIsland::WARDS[:riverside][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:riverside][:unit_code_value] }
      association :parent, factory: :millbrook_district
    end

    factory :oldtown_ward do
      name { NormalIsland::WARDS[:oldtown][:name] }
      unit { NormalIsland::WARDS[:oldtown][:unit] }
      unit_code_key { NormalIsland::WARDS[:oldtown][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:oldtown][:unit_code_value] }
      association :parent, factory: :millbrook_district
    end

    factory :greenfield_ward do
      name { NormalIsland::WARDS[:greenfield][:name] }
      unit { NormalIsland::WARDS[:greenfield][:unit] }
      unit_code_key { NormalIsland::WARDS[:greenfield][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:greenfield][:unit_code_value] }
      association :parent, factory: :millbrook_district
    end

    factory :harbourside_ward do
      name { NormalIsland::WARDS[:harbourside][:name] }
      unit { NormalIsland::WARDS[:harbourside][:unit] }
      unit_code_key { NormalIsland::WARDS[:harbourside][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:harbourside][:unit_code_value] }
      association :parent, factory: :millbrook_district
    end

    # Wards - Ashdale District
    factory :hillcrest_ward do
      name { NormalIsland::WARDS[:hillcrest][:name] }
      unit { NormalIsland::WARDS[:hillcrest][:unit] }
      unit_code_key { NormalIsland::WARDS[:hillcrest][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:hillcrest][:unit_code_value] }
      association :parent, factory: :ashdale_district
    end

    factory :valleyview_ward do
      name { NormalIsland::WARDS[:valleyview][:name] }
      unit { NormalIsland::WARDS[:valleyview][:unit] }
      unit_code_key { NormalIsland::WARDS[:valleyview][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:valleyview][:unit_code_value] }
      association :parent, factory: :ashdale_district
    end

    # Wards - Seaview District
    factory :cliffside_ward do
      name { NormalIsland::WARDS[:cliffside][:name] }
      unit { NormalIsland::WARDS[:cliffside][:unit] }
      unit_code_key { NormalIsland::WARDS[:cliffside][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:cliffside][:unit_code_value] }
      association :parent, factory: :seaview_district
    end

    factory :beachfront_ward do
      name { NormalIsland::WARDS[:beachfront][:name] }
      unit { NormalIsland::WARDS[:beachfront][:unit] }
      unit_code_key { NormalIsland::WARDS[:beachfront][:unit_code_key] }
      unit_code_value { NormalIsland::WARDS[:beachfront][:unit_code_value] }
      association :parent, factory: :seaview_district
    end
  end
end
