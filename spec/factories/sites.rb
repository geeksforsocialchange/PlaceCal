# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
#
#  id                :bigint           not null, primary key
#  badge_zoom_level  :string
#  description       :text
#  description_html  :string
#  events_count      :integer          default(0), not null
#  footer_logo       :string
#  hero_alttext      :string
#  hero_image        :string
#  hero_image_credit :string
#  hero_text         :string
#  is_published      :boolean          default(FALSE), not null
#  logo              :string
#  name              :string           not null
#  partners_count    :integer          default(0), not null
#  place_name        :string
#  slug              :string           not null
#  tagline           :string
#  theme             :string
#  url               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_admin_id     :bigint
#
# Indexes
#
#  index_sites_is_published       (is_published)
#  index_sites_on_events_count    (events_count)
#  index_sites_on_partners_count  (partners_count)
#  index_sites_slug               (slug) UNIQUE
#  index_sites_url                (url)
#
# Foreign Keys
#
#  fk_rails_...  (site_admin_id => users.id)
#
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
        create(:sites_neighbourhood, site: site, neighbourhood: district)
      end
    end

    factory :ashdale_site do
      name { NormalIsland::SITES[:ashdale_connect][:name] }
      slug { NormalIsland::SITES[:ashdale_connect][:slug] }
      tagline { NormalIsland::SITES[:ashdale_connect][:tagline] }

      after(:create) do |site|
        district = create(:ashdale_district)
        create(:sites_neighbourhood, site: site, neighbourhood: district)
      end
    end

    factory :coastshire_site do
      name { NormalIsland::SITES[:coastshire_events][:name] }
      slug { NormalIsland::SITES[:coastshire_events][:slug] }
      tagline { NormalIsland::SITES[:coastshire_events][:tagline] }

      after(:create) do |site|
        county = create(:coastshire_county)
        create(:sites_neighbourhood, site: site, neighbourhood: county)
      end
    end
  end

  factory :sites_neighbourhood do
    association :site
    association :neighbourhood
    relation_type { "Primary" }
  end
end
