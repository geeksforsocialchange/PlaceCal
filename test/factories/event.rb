# frozen_string_literal: true

FactoryBot.define do
  factory(:event) do
    sequence(:summary) { |n| "N.A. (Narcotics Anonymous) - Meetup #{n}" }
    raw_location_from_source do
      "Unformatted Address, Ungeolocated Lane, Manchester"
    end
    dtstart { DateTime.now + 1.day }
    dtend { DateTime.now + 1.day + 2.hours }
    is_active { true }
    address
    calendar

    trait :with_place do
      association :place, factory: :partner
    end

    trait :with_partner do
      association :partner
    end

    after(:build) { |event| event.partner = create(:partner) }
  end
end
