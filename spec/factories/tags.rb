# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  system_tag  :boolean          default(FALSE), not null
#  type        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tags_name_type  (name,type) UNIQUE
#  index_tags_slug_type  (slug,type) UNIQUE
#
FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    type { "Facility" }
    description { Faker::Lorem.sentence }

    # Tag types
    factory :category, aliases: [:category_tag], class: "Category" do
      type { "Category" }
      sequence(:name) { |n| "Category #{n}" }
    end

    factory :facility, aliases: [:facility_tag], class: "Facility" do
      type { "Facility" }
      sequence(:name) { |n| "Facility #{n}" }
    end

    factory :partnership, aliases: [:partnership_tag], class: "Partnership" do
      type { "Partnership" }
      sequence(:name) { |n| "Partnership #{n}" }
    end

    # Normal Island tags
    factory :health_wellbeing_tag, class: "Category" do
      name { "Health & Wellbeing" }
      type { "Category" }
    end

    factory :arts_culture_tag, class: "Category" do
      name { "Arts & Culture" }
      type { "Category" }
    end

    factory :sports_fitness_tag, class: "Category" do
      name { "Sports & Fitness" }
      type { "Category" }
    end

    factory :wheelchair_accessible_tag, class: "Facility" do
      name { "Wheelchair Accessible" }
      type { "Facility" }
    end

    factory :parking_available_tag, class: "Facility" do
      name { "Parking Available" }
      type { "Facility" }
    end

    factory :millbrook_together_tag, aliases: [:millbrook_partnership_tag], class: "Partnership" do
      name { "Millbrook Together" }
      type { "Partnership" }
    end

    factory :coastal_alliance_tag, class: "Partnership" do
      name { "Coastal Alliance" }
      type { "Partnership" }
    end

    # Legacy compatibility factories
    factory :community_services_tag, class: "Category" do
      name { "Community Services" }
      type { "Category" }
    end
  end
end
