# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    sequence(:name) { |n| "Collection #{n}" }
    description { Faker::Lorem.paragraph }
    route { "named-route" }

    factory :collection_with_events do
      transient do
        event_count { 3 }
      end

      after(:create) do |collection, evaluator|
        evaluator.event_count.times do
          collection.events << create(:event)
        end
      end
    end
  end
end
