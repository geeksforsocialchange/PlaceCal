# frozen_string_literal: true

require_relative "../../lib/normal_island"

FactoryBot.define do
  factory :site do
    sequence(:name) { |n| "Site #{n}" }
    sequence(:slug) { |n| "site-#{n}" }
    url { "https://#{slug}.placecal.org" }
    tagline { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    theme { "pink" }
    hero_image_credit { "Normal Island Photography" }

    # Normal Island sites
    factory :millbrook_site do
      name { NormalIsland::SITES[:millbrook_community_calendar][:name] }
      slug { NormalIsland::SITES[:millbrook_community_calendar][:slug] }
      tagline { NormalIsland::SITES[:millbrook_community_calendar][:tagline] }

      after(:create) do |site|
        district = create(:millbrook_district)
        create(:sites_neighbourhood, site: site, neighbourhood: district, relation_type: "Primary")
      end
    end

    factory :ashdale_site do
      name { NormalIsland::SITES[:ashdale_connect][:name] }
      slug { NormalIsland::SITES[:ashdale_connect][:slug] }
      tagline { NormalIsland::SITES[:ashdale_connect][:tagline] }

      after(:create) do |site|
        district = create(:ashdale_district)
        create(:sites_neighbourhood, site: site, neighbourhood: district, relation_type: "Primary")
      end
    end

    factory :coastshire_site do
      name { NormalIsland::SITES[:coastshire_events][:name] }
      slug { NormalIsland::SITES[:coastshire_events][:slug] }
      tagline { NormalIsland::SITES[:coastshire_events][:tagline] }

      after(:create) do |site|
        county = create(:coastshire_county)
        create(:sites_neighbourhood, site: site, neighbourhood: county, relation_type: "Primary")
      end
    end

    factory :default_site do
      name { NormalIsland::SITES[:normal_island_central][:name] }
      slug { NormalIsland::SITES[:normal_island_central][:slug] }
      tagline { NormalIsland::SITES[:normal_island_central][:tagline] }
    end
  end

  factory :sites_neighbourhood do
    association :site
    association :neighbourhood
    relation_type { "Primary" }
  end
end
