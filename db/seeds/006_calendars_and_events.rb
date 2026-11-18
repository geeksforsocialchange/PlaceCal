# frozen_string_literal: true

module SeedCalendarsAndEvents # rubocop:disable Metrics/ModuleLength
  module BypassCalendarRemoteChecks
    def check_source_reachable; end
  end

  EVENT_TITLES = [
    'Art Exhibition Opening',
    'Bike Repair Workshop',
    'Board Games Night',
    'Children\'s Storytime',
    'Choir Practice',
    'Citizens Advice Surgery',
    'Clothes Swap',
    'Coding for Beginners',
    'Coffee Morning',
    'Community Choir',
    'Community Clean-up',
    'Community Lunch',
    'Cooking Class',
    'Creative Writing Workshop',
    'Crochet Circle',
    'Dance Fitness Class',
    'Digital Skills Drop-in',
    'Drama Workshop',
    'Family Fun Day',
    'Film Screening and Discussion',
    'First Aid Training',
    'Free Legal Advice Clinic',
    'Gardening Workshop',
    'Homework Help Club',
    'Job Club',
    'Knitting Circle',
    'Language Exchange Cafe',
    'Life Drawing Class',
    'Litter Pick',
    'Local History Talk',
    'Meditation Session',
    'Mindfulness Workshop',
    'Morning Yoga Session',
    'Nature Walk',
    'Open Drop-in',
    'Parent and Toddler Group',
    'Photography Walk',
    'Pottery Workshop',
    'Quiz Night',
    'Sewing and Mending Workshop',
    'Soup Kitchen',
    'Spoken Word Open Mic',
    'Storytelling Evening',
    'Table Tennis Tournament',
    'Tai Chi in the Park',
    'Ukulele for Beginners',
    'Volunteer Training',
    'Watercolour Painting Class',
    'Wellbeing Check-in',
    'Zumba Class'
  ].freeze

  EVENT_TIMES = [
    { hour: 9, min: 0 },
    { hour: 10, min: 30 },
    { hour: 12, min: 0 },
    { hour: 14, min: 0 },
    { hour: 18, min: 30 },
    { hour: 19, min: 0 }
  ].freeze

  # Stored the way the ICS importer stores Icalendar::Values::Recur; the fortnightly rule still reads as "Weekly".
  RRULE_TEXTS = %w[FREQ=WEEKLY FREQ=MONTHLY;BYDAY=1SA FREQ=WEEKLY;INTERVAL=2].freeze
  RRULES = RRULE_TEXTS.map { Icalendar::Values::Recur.new(it).as_json }.freeze

  MEETING_URLS = %w[
    https://meet.jit.si/placecal-seed-%d
    https://zoom.us/j/9%09d
    https://meet.google.com/plc-seed-%03d
  ].freeze

  # Each calendar imports its own events from a file the dev server serves, so imports succeed and keep them
  FEEDS_DIR = Rails.public_path.join('seed-feeds')

  def self.feed_url(partner)
    "http://lvh.me:#{ENV.fetch('PORT', 3000)}/seed-feeds/#{partner.id}.ics"
  end

  def self.write_feed(partner, events)
    ics = Icalendar::Calendar.new
    events.each { |event| ics.add_event(feed_event(event)) }
    FileUtils.mkdir_p(FEEDS_DIR)
    File.write(FEEDS_DIR.join("#{partner.id}.ics"), ics.to_ical)
  end

  def self.feed_event(event)
    Icalendar::Event.new.tap do |entry|
      entry.uid = event.uid
      entry.summary = event.summary
      entry.description = event.description
      entry.dtstart = Icalendar::Values::DateTime.new(event.dtstart.utc, tzid: 'UTC')
      entry.dtend = Icalendar::Values::DateTime.new(event.dtend.utc, tzid: 'UTC')
      entry.rrule = RRULE_TEXTS[RRULES.index(event.rrule.first)] if event.rrule.present?
      entry.location = address_text(event.address) if event.address
      entry.append_custom_property('X-GOOGLE-CONFERENCE', event.online_address.url) if event.online_address
    end
  end

  def self.address_text(address)
    [address.street_address, address.street_address2, address.street_address3, address.city, address.postcode].compact_blank.join(', ')
  end

  def self.run
    $stdout.puts 'Calendars and Events'

    today = Time.zone.today
    event_count = 0

    Partner.find_each.with_index do |partner, partner_idx|
      next if Calendar.exists?(organiser: partner)

      calendar = Calendar.new(
        name: "#{partner.name} Calendar",
        organiser: partner,
        source: feed_url(partner),
        calendar_state: 'idle',
        strategy: 'event'
      )
      calendar.extend BypassCalendarRemoteChecks
      calendar.save!

      # Each partner gets 3-10 events
      num_events = 3 + (partner_idx % 8)

      events = Array.new(num_events) do |i|
        # Mix of past and future dates, starting from 2 days ago
        day_offset = case i
                     when 0 then -rand(7..30)           # past month
                     when 1 then -rand(1..7)            # past week
                     else rand(-2..60)                   # 2 days ago to 2 months out
                     end

        time = EVENT_TIMES[(partner_idx + i) % EVENT_TIMES.length]
        title = EVENT_TITLES[(partner_idx + i) % EVENT_TITLES.length]

        start = (today + day_offset.days).to_datetime.change(hour: time[:hour], min: time[:min])
        k = partner_idx + i
        # Odd multiples of 5 are online only; repeating online events (multiples of 20) keep their address.
        online = (k % 5).zero?
        online_address = OnlineAddress.find_or_create_by!(url: format(MEETING_URLS[(k / 5) % MEETING_URLS.length], k), link_type: :direct) if online
        Event.create!(
          uid: "seed_event_#{partner.id}_#{i}", summary: title,
          description: "#{title} at #{partner.name}. Everyone welcome!",
          dtstart: start, dtend: start + 90.minutes,
          organiser: partner,
          calendar:,
          address: online && k % 10 == 5 ? nil : partner.address,
          online_address:,
          rrule: (k % 4).zero? ? [RRULES[(k / 4) % RRULES.length]] : nil
        )
      end
      write_feed(partner, events)
      event_count += events.size

      $stdout.puts "  #{partner.name}: #{num_events} events"
    end

    $stdout.puts "  Total events: #{event_count}"
  end
end

SeedCalendarsAndEvents.run
