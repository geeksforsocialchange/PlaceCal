# frozen_string_literal: true

FactoryBot.define do
  factory :turf do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    slug { name.parameterize }
  end
end
