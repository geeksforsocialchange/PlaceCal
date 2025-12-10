# frozen_string_literal: true

FactoryBot.define do
  factory :calendar do
    sequence(:name) { |n| "Calendar #{n}" }
    source { 'https://calendar.google.com/calendar/ical/example/public/basic.ics' }
    strategy { 'event' }
    association :partner

    # Auto-set place when strategy requires it
    after(:build) do |calendar|
      if %w[place room_number event_override].include?(calendar.strategy) && calendar.place.nil?
        calendar.place = calendar.partner
      end
    end

    factory :ics_calendar do
      source { 'https://example.com/calendar.ics' }
      strategy { 'event' }
    end

    factory :eventbrite_calendar do
      source { 'https://www.eventbrite.co.uk/o/example-org-12345678901' }
      strategy { 'event' }
    end

    factory :google_calendar do
      source { 'https://calendar.google.com/calendar/ical/example@group.calendar.google.com/public/basic.ics' }
      strategy { 'event' }
    end

    factory :outlook_calendar do
      source { 'https://outlook.office365.com/owa/calendar/example/calendar.ics' }
      strategy { 'event' }
    end

    # Calendar with place strategy (uses partner as place)
    factory :place_calendar do
      strategy { 'place' }
    end
  end
end
