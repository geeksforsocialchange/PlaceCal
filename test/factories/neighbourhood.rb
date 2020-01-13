# frozen_string_literal: true

FactoryBot.define do
  factory :neighbourhood do
    sequence(:name) do |n|
      "Neighbourhood #{n}"
    end
    sequence(:ward) do |n|
      "Ward #{n}"
    end
  end
end
