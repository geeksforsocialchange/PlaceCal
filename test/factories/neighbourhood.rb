# frozen_string_literal: true

FactoryBot.define do
  factory :neighbourhood do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
  end
end
