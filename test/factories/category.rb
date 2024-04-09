# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) do |n|
      "Hulme #{n}"
    end

    slug { name.parameterize }
    description { 'I am a tag' }
    type { 'Category' }
  end
end
