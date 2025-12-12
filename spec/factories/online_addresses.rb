# frozen_string_literal: true

FactoryBot.define do
  factory :online_address do
    url { Faker::Internet.url }
    link_type { 'indirect' }

    factory :direct_online_address do
      url { 'https://zoom.us/j/1234567890' }
      link_type { 'direct' }
    end
  end
end
