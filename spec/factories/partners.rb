# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id                      :bigint           not null, primary key
#  accessibility_info      :text
#  accessibility_info_html :string
#  admin_email             :string
#  admin_name              :string
#  booking_info            :text
#  calendar_email          :string
#  calendar_name           :string
#  calendar_phone          :string
#  can_be_assigned_events  :boolean          default(FALSE), not null
#  description             :text
#  description_html        :string
#  facebook_link           :string
#  hidden                  :boolean          default(FALSE), not null
#  hidden_reason           :text
#  hidden_reason_html      :string
#  image                   :string
#  instagram_handle        :string
#  is_a_place              :boolean          default(FALSE), not null
#  name                    :string           not null
#  opening_times           :jsonb
#  partner_email           :string
#  partner_name            :string
#  partner_phone           :string
#  public_email            :string
#  public_name             :string
#  public_phone            :string
#  slug                    :string
#  summary                 :string
#  summary_html            :string
#  twitter_handle          :string
#  url                     :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  address_id              :bigint
#  hidden_blame_id         :integer
#
# Indexes
#
#  index_partners_hidden         (hidden)
#  index_partners_lower_name_    (lower((name)::text)) UNIQUE
#  index_partners_on_address_id  (address_id)
#  index_partners_on_slug        (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#
require_relative "../../lib/normal_island"

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partner #{n}" }
    summary { Faker::Lorem.paragraph(sentence_count: 2) }
    description { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    public_email { Faker::Internet.email }
    public_phone { "0161 234 5678" }
    opening_times { "[]" }
    association :address, factory: :riverside_address

    # Normal Island partners
    factory :riverside_community_hub, aliases: [:riverside_partner] do
      name { NormalIsland::PARTNERS[:riverside_community_hub][:name] }
      summary { NormalIsland::PARTNERS[:riverside_community_hub][:summary] }
      # with contact details for spec/components/contact_details_component_spec.rb
      twitter_handle { "rchtwit" }
      instagram_handle { "rchinsta" }
      facebook_link { "rchfb" }
      association :address, factory: :riverside_address
    end

    factory :oldtown_library do
      name { NormalIsland::PARTNERS[:oldtown_library][:name] }
      summary { NormalIsland::PARTNERS[:oldtown_library][:summary] }
      # without contact details for spec/components/contact_details_component_spec.rb
      association :address, factory: :oldtown_address
    end

    factory :greenfield_youth_centre do
      name { NormalIsland::PARTNERS[:greenfield_youth_centre][:name] }
      summary { NormalIsland::PARTNERS[:greenfield_youth_centre][:summary] }
      association :address, factory: :greenfield_address
    end

    factory :harbourside_arts_centre do
      name { NormalIsland::PARTNERS[:harbourside_arts_centre][:name] }
      summary { NormalIsland::PARTNERS[:harbourside_arts_centre][:summary] }
      association :address, factory: :harbourside_address
    end

    factory :ashdale_sports_club do
      name { NormalIsland::PARTNERS[:ashdale_sports_club][:name] }
      summary { NormalIsland::PARTNERS[:ashdale_sports_club][:summary] }
      association :address, factory: :hillcrest_address
    end

    factory :coastline_wellness_centre do
      name { NormalIsland::PARTNERS[:coastline_wellness_centre][:name] }
      summary { NormalIsland::PARTNERS[:coastline_wellness_centre][:summary] }
      association :address, factory: :cliffside_address
    end

    # Partner with service areas (plus base address for validation)
    factory :mobile_partner do
      name { "Mobile Services" }
      summary { "Community services delivered across multiple locations" }
      # Needs an address to pass validation, service areas added after create
      association :address, factory: :riverside_address

      transient do
        service_area_wards { [] }
      end

      after(:create) do |partner, evaluator|
        evaluator.service_area_wards.each do |ward|
          create(:service_area, partner: partner, neighbourhood: ward)
        end
      end
    end

    # Legacy compatibility - partner with service area
    factory :ashton_service_area_partner do
      name { "Ashton Service Partner" }
      summary { "A partner with service areas" }
      association :address, factory: :riverside_address

      after(:create) do |partner|
        create(:service_area, partner: partner, neighbourhood: create(:neighbourhood))
      end
    end
  end
end
