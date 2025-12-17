# frozen_string_literal: true

FactoryBot.define do
  factory :supporter do
    sequence(:name) { |n| "Supporter #{n}" }
    url { Faker::Internet.url }
    description { Faker::Lorem.sentence }
  end
end
