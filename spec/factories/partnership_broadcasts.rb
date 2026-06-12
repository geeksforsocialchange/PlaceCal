# frozen_string_literal: true

FactoryBot.define do
  factory :partnership_broadcast do
    partnership
    association :sender, factory: :user
    sequence(:subject) { |n| "Broadcast #{n}" }
    body { "An update from your partnership." }
  end
end
