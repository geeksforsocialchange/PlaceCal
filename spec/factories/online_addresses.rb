# frozen_string_literal: true

FactoryBot.define do
  factory :online_address do
    url { Faker::Internet.url }
    link_type { 'other' }

    factory :zoom_address do
      url { 'https://zoom.us/j/1234567890' }
      link_type { 'zoom' }
    end

    factory :teams_address do
      url { 'https://teams.microsoft.com/l/meetup-join/example' }
      link_type { 'teams' }
    end

    factory :youtube_address do
      url { 'https://www.youtube.com/watch?v=example' }
      link_type { 'youtube' }
    end
  end
end
