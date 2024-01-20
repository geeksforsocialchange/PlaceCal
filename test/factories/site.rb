# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    tagline { 'The Community Calendar' }
    hero_image_credit { 'Place Cal' }
    domain { "https://#{name.parameterize}.placecal.org" }
    slug { name.parameterize }
    theme { :pink }
    is_published { true }

    association :site_admin, factory: :user

    factory :site_local do
      tagline { "Neighbourhood's Community Calendar" }
    end
  end
end
