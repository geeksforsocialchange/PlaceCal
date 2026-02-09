# frozen_string_literal: true

module SeedCalendarsAndEvents
  module BypassCalendarRemoteChecks
    def check_source_reachable; end
  end

  EVENT_TITLES = [
    'Morning Yoga Session',
    'Community Lunch',
    'Open Drop-in',
    'Creative Writing Workshop',
    'Volunteer Training',
    'Family Fun Day',
    'Board Games Night',
    'Gardening Workshop',
    'Wellbeing Check-in',
    'Coffee Morning',
    'Knitting Circle',
    'Coding for Beginners',
    'Local History Talk',
    'Choir Practice',
    'Art Exhibition Opening',
    'Quiz Night',
    'Meditation Session',
    'Children\'s Storytime',
    'Job Club',
    'Cooking Class'
  ].freeze

  EVENT_TIMES = [
    { hour: 9, min: 0 },
    { hour: 10, min: 30 },
    { hour: 12, min: 0 },
    { hour: 14, min: 0 },
    { hour: 18, min: 30 },
    { hour: 19, min: 0 }
  ].freeze

  def self.run
    $stdout.puts 'Calendars and Events'

    today = Time.zone.today
    event_count = 0

    Partner.find_each.with_index do |partner, partner_idx|
      # Skip if this partner already has a calendar
      next if Calendar.exists?(partner: partner)

      calendar = Calendar.new(
        name: "#{partner.name} Calendar",
        partner: partner,
        source: "https://example.com/cal/#{partner.id}",
        calendar_state: 'idle',
        strategy: 'no_location'
      )
      calendar.extend BypassCalendarRemoteChecks
      calendar.save!

      # Each partner gets 3-10 events
      num_events = 3 + (partner_idx % 8)

      num_events.times do |i|
        # Mix of past and future dates, starting from 2 days ago
        day_offset = case i
                     when 0 then -rand(7..30)           # past month
                     when 1 then -rand(1..7)            # past week
                     else rand(-2..60)                   # 2 days ago to 2 months out
                     end

        time = EVENT_TIMES[(partner_idx + i) % EVENT_TIMES.length]
        title = EVENT_TITLES[(partner_idx + i) % EVENT_TITLES.length]

        Event.create!(
          uid: "seed_event_#{partner.id}_#{i}",
          summary: title,
          description: "#{title} at #{partner.name}. Everyone welcome!",
          dtstart: (today + day_offset.days).to_datetime.change(hour: time[:hour], min: time[:min]),
          partner: partner,
          calendar: calendar,
          address: partner.address
        )
        event_count += 1
      end

      $stdout.puts "  #{partner.name}: #{num_events} events"
    end

    $stdout.puts "  Total events: #{event_count}"
  end
end

SeedCalendarsAndEvents.run
