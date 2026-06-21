# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                       :bigint           not null, primary key
#  are_spaces_available     :string
#  description              :text
#  description_html         :string
#  dtend                    :datetime
#  dtstart                  :datetime         not null
#  footer                   :text
#  is_active                :boolean          default(TRUE), not null
#  notices                  :jsonb
#  publisher_url            :string
#  raw_location_from_source :text
#  rrule                    :jsonb
#  summary                  :text             not null
#  summary_html             :string
#  uid                      :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  address_id               :bigint
#  calendar_id              :bigint
#  online_address_id        :bigint
#  organiser_id             :bigint           not null
#  place_id                 :bigint
#
# Indexes
#
#  index_events_address_id                   (address_id)
#  index_events_calendar_id_dtstart          (calendar_id,dtstart)
#  index_events_dtstart                      (dtstart)
#  index_events_on_online_address_id         (online_address_id)
#  index_events_on_organiser_id_and_dtstart  (organiser_id,dtstart)
#  index_events_on_place_id                  (place_id)
#  index_events_uid                          (uid)
#  index_events_unique_per_calendar          (calendar_id,uid,dtstart,dtend) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (online_address_id => online_addresses.id)
#  fk_rails_...  (organiser_id => partners.id)
#  fk_rails_...  (place_id => partners.id)
#
FactoryBot.define do
  factory :event do
    sequence(:summary) { |n| "Event #{n}" }
    description { Faker::Lorem.paragraph }
    dtstart { 1.day.from_now.at_beginning_of_hour }
    dtend { 1.day.from_now.at_beginning_of_hour + 2.hours }
    association :organiser, factory: :partner
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
