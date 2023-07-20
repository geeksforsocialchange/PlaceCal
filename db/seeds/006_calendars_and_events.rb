# frozen_string_literal: true

module SeedCalendarsAndEvents
  module BypassCalendarRemoteChecks
    # calendars will validate that the source is valid by trying
    # to connect to the remote end and do a HTTP GET.
    def check_source_reachable
      # $stdout.puts 'SILENCE, YOU!'
    end
  end

  def self.run
    $stdout.puts 'Calendars and Events'

    partner = Partner.first

    calendar = Calendar.new(
      name: 'Sample Calendar',
      partner: partner,
      source: 'https://placecal.org',
      calendar_state: 'idle',
      strategy: 'no_location'
    )
    calendar.extend BypassCalendarRemoteChecks
    calendar.save!

    # events
    today = Time.zone.today

    # 1 week ago
    Event.create!(
      uid: 'event_0001',
      description: 'An event that happened last week',
      summary: 'Event for last week',
      dtstart: today - 1.week,
      partner: partner,
      calendar: calendar
    )

    # 1 month ago
    Event.create!(
      uid: 'event_0002',
      description: 'An event that happened last month',
      summary: 'Event for last month',
      dtstart: today - 1.month,
      partner: partner,
      calendar: calendar
    )

    # 1 year ago
    Event.create!(
      uid: 'event_0003',
      description: 'An event that happened last year',
      summary: 'Event for last year',
      dtstart: today - 1.year,
      partner: partner,
      calendar: calendar
    )

    # 1 weeks time
    Event.create!(
      uid: 'event_0004',
      description: 'An event that will happen next week',
      summary: 'Event for next week',
      dtstart: today + 1.week,
      partner: partner,
      calendar: calendar
    )

    # 1 months time
    Event.create!(
      uid: 'event_0005',
      description: 'An event that will happen next month',
      summary: 'Event for next month',
      dtstart: today + 1.month,
      partner: partner,
      calendar: calendar
    )

    # 1 years time
    Event.create!(
      uid: 'event_0006',
      description: 'An event that will happen next year',
      summary: 'Event for next year',
      dtstart: today + 1.year,
      partner: partner,
      calendar: calendar
    )
  end
end

SeedCalendarsAndEvents.run
