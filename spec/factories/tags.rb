# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    type { 'Facility' }
    description { Faker::Lorem.sentence }

    # Tag types
    factory :category, class: 'Category' do
      type { 'Category' }
      sequence(:name) { |n| "Category #{n}" }
    end

    factory :facility, class: 'Facility' do
      type { 'Facility' }
      sequence(:name) { |n| "Facility #{n}" }
    end

    factory :partnership, class: 'Partnership' do
      type { 'Partnership' }
      sequence(:name) { |n| "Partnership #{n}" }
    end

    # Normal Island tags
    factory :health_wellbeing_tag, class: 'Category' do
      name { 'Health & Wellbeing' }
      type { 'Category' }
    end

    factory :arts_culture_tag, class: 'Category' do
      name { 'Arts & Culture' }
      type { 'Category' }
    end

    factory :sports_fitness_tag, class: 'Category' do
      name { 'Sports & Fitness' }
      type { 'Category' }
    end

    factory :wheelchair_accessible_tag, class: 'Facility' do
      name { 'Wheelchair Accessible' }
      type { 'Facility' }
    end

    factory :parking_available_tag, class: 'Facility' do
      name { 'Parking Available' }
      type { 'Facility' }
    end

    factory :millbrook_together_tag, class: 'Partnership' do
      name { 'Millbrook Together' }
      type { 'Partnership' }
    end

    factory :coastal_alliance_tag, class: 'Partnership' do
      name { 'Coastal Alliance' }
      type { 'Partnership' }
    end
  end
end
