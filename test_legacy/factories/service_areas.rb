# frozen_string_literal: true

FactoryBot.define do
  factory :ashton_service_area, class: 'ServiceArea' do
    association :neighbourhood, factory: :ashton_neighbourhood
  end
end
