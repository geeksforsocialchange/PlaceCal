# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence(:summary) { |n| "Event #{n}" }
    description { Faker::Lorem.paragraph }
    dtstart { 1.day.from_now.at_beginning_of_hour }
    dtend { 1.day.from_now.at_beginning_of_hour + 2.hours }
    association :partner
    association :calendar
    association :address

    # Time-based variants
    factory :past_event do
      dtstart { 1.week.ago.at_beginning_of_hour }
      dtend { 1.week.ago.at_beginning_of_hour + 2.hours }
    end

    # Note time is frozen by `timecop` gem - see rails_helper.rb
    factory :future_event do
      dtstart { 1.week.from_now.at_beginning_of_hour }
      dtend { 1.week.from_now.at_beginning_of_hour + 2.hours }
    end

    factory :today_event do
      dtstart { Time.current.at_beginning_of_hour + 2.hours }
      dtend { Time.current.at_beginning_of_hour + 4.hours }
    end

    # Location variants
    factory :online_event do
      address { nil }
      association :online_address
    end

    factory :hybrid_event do
      association :address
      association :online_address
    end

    # Recurring event
    factory :recurring_event do
      rrule { "FREQ=WEEKLY;COUNT=10" }
    end
  end
end
