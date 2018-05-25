# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    hero_image_credit 'Place Cal'
    domain { name.parameterize }
    slug { name.parameterize }
  end
end
