# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) do |n|
      "Hulme #{n}"
    end

    slug { name.parameterize }
    description { 'I am a tag' }
    type { 'Facility' }

    factory :system_tag do
      system_tag { true }
    end

    factory :partnership do
      sequence(:name) { |n| "Partnership Tag #{n}" }
      type { 'Partnership' }
    end
  end
end
