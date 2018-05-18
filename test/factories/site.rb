# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    domain { name.parameterize }
    slug { name.parameterize }
  end
end
