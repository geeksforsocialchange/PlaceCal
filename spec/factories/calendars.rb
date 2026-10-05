# frozen_string_literal: true

# == Schema Information
#
# Table name: calendars
#
#  id                   :bigint           not null, primary key
#  api_token            :string
#  calendar_state       :string           default("idle")
#  checksum_updated_at  :datetime
#  critical_error       :text
#  import_started_at    :datetime
#  importer_mode        :string           default("auto")
#  importer_used        :string
#  is_working           :boolean          default(TRUE), not null
#  last_checksum        :string
#  last_import_at       :datetime
#  name                 :string           not null
#  notice_count         :integer
#  notices              :jsonb
#  public_contact_email :string
#  public_contact_name  :string
#  public_contact_phone :string
#  source               :string           not null
#  strategy             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  organiser_id         :bigint           not null
#  place_id             :bigint
#
# Indexes
#
#  index_calendars_on_calendar_state  (calendar_state)
#  index_calendars_on_organiser_id    (organiser_id)
#  index_calendars_on_place_id        (place_id)
#  index_calendars_source             (source) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => partners.id)
#  fk_rails_...  (place_id => partners.id)
#
FactoryBot.define do
  factory :calendar do
    sequence(:name) { |n| "Calendar #{n}" }
    sequence(:source) { |n| "https://calendar.google.com/calendar/ical/example#{n}/public/basic.ics" }
    strategy { "event" }
    association :organiser, factory: :partner

    # Auto-set place when strategy requires it
    after(:build) do |calendar|
      calendar.place = calendar.organiser if %w[place room_number event_override].include?(calendar.strategy) && calendar.place.nil?
    end

    # Skip source validation in tests (HTTP request)
    before(:create) do |calendar|
      calendar.define_singleton_method(:check_source_reachable) { true }
    end

    factory :ics_calendar do
      source { "https://example.com/calendar.ics" }
      strategy { "event" }
    end

    factory :eventbrite_calendar do
      source { "https://www.eventbrite.co.uk/o/example-org-12345678901" }
      strategy { "event" }
    end

    factory :google_calendar do
      source { "https://calendar.google.com/calendar/ical/example@group.calendar.google.com/public/basic.ics" }
      strategy { "event" }
    end

    factory :outlook_calendar do
      source { "https://outlook.office365.com/owa/calendar/example/calendar.ics" }
      strategy { "event" }
    end

    # Calendar with place strategy (uses partner as place)
    factory :place_calendar do
      strategy { "place" }
    end
  end
end
