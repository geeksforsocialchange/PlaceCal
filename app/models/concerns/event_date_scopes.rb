# frozen_string_literal: true

# Event scopes that pick events by their start date
module EventDateScopes
  extend ActiveSupport::Concern

  included do
    # Events starting on app-zone dates first..last inclusive. dtstart is stored in UTC,
    # so SQL DATE(dtstart) would put events from 00:00 to 01:00 BST on the day before.
    scope :starting_between_days, lambda { |first, last|
      where(dtstart: first.to_date.in_time_zone...last.to_date.next_day.in_time_zone)
    }

    scope :find_by_day, ->(day) { starting_between_days(day, day) }

    # Monday to Sunday
    scope :find_by_week, lambda { |day|
      date = day.to_date
      starting_between_days(date.beginning_of_week, date.end_of_week)
    }

    scope :find_next_7_days, ->(day) { starting_between_days(day, day.to_date + 6.days) }

    scope :for_month, ->(day) { starting_between_days(day, day.to_date.end_of_month) }

    scope :future, ->(day) { where(dtstart: day.midnight..) }

    scope :upcoming, -> { where(dtstart: DateTime.current.beginning_of_day..) }
    scope :past, -> { where(dtstart: ..DateTime.current.beginning_of_day) }

    # Global feed; six months ahead keeps busy sites' subscriptions small enough for calendar apps
    scope :ical_feed, -> { where(dtstart: 1.week.ago...6.months.from_now) }
  end
end
