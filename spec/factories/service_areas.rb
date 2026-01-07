# frozen_string_literal: true

FactoryBot.define do
  factory :service_area do
    association :partner
    association :neighbourhood
  end
end
