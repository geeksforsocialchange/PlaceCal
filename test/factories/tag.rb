# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    slug { name.parameterize }
    description { 'I am a tag' }
    edit_permission { 'root' }

    type { 'FacilityTag' }

    factory :tag_public, class: :tag do
      description { 'I am a tag everyone can edit' }
      edit_permission { 'all' }
    end

    factory :system_tag do
      system_tag { true }
    end

    factory :facility_tag do # property tag
      type { 'FacilityTag' }
    end

    factory :partnership_tag do # site tag
      type { 'PartnershipTag' }
    end

    factory :category_tag do
      type { 'CategoryTag' }
    end
  end
end
