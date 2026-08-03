# frozen_string_literal: true

# Serving event data as downloadable feeds: building iCal calendars and
# tracking iCal/CSV downloads in AppSignal and Plausible.
module EventFeeds
  extend ActiveSupport::Concern

  private

  # Create a calendar from array of events
  def create_calendar(events, title = nil)
    cal = Icalendar::Calendar.new
    cal.x_wr_calname = title || 'PlaceCal'
    site_url = current_site&.url || 'https://placecal.org'
    events.each do |event|
      ical = create_ical_event(event, site_url)
      cal.add_event(ical)
    end
    cal
  end

  # Convert an event object into an ics listing
  def create_ical_event(source, site_url)
    event_url = "#{site_url}/events/#{source.id}"
    event = Icalendar::Event.new
    event.uid = source.uid.presence || "event-#{source.id}@placecal.org"
    event.dtstart = source.dtstart
    event.dtend = source.dtend
    event.summary = source.summary
    event.description = "#{unescape_ical_text(source.description)}\n\n#{event_url}"
    event.url = event_url
    event.location = source.location
    event
  end

  # Unescape iCal escape sequences stored in the DB from source calendar imports.
  #
  # We do this ourselves rather than using icalendar gem's Text unescaping because:
  # 1. The gem only handles standard RFC 5545 escapes (\n \, \; \\), not non-standard
  #    \' and \" that some source calendars produce
  # 2. Simpler to have one function that handles everything than split responsibility
  #
  # Order matters: unescape \\ last so we don't clobber other sequences.
  def unescape_ical_text(text)
    return '' if text.blank?

    text.gsub('\\n', "\n")
        .gsub('\\,', ',')
        .gsub('\\;', ';')
        .gsub("\\'", "'")
        .gsub('\\"', '"')
        .gsub('\\\\', '\\')
  end

  # Track iCal feed downloads in AppSignal and Plausible.
  # Sets a distinct AppSignal action name and sends a server-side pageview
  # to Plausible (iCal clients don't execute JavaScript).
  def track_ical_download
    track_file_download('ical_feed')
  end

  # Track CSV event exports (see EventsCsv) the same way.
  def track_csv_download
    track_file_download('csv_export')
  end

  def track_file_download(action)
    Appsignal::Transaction.current.set_action("#{self.class.name}##{action}")

    return unless Rails.env.production?

    Thread.new do
      uri = URI('https://plausible.io/api/event')
      Net::HTTP.post(
        uri,
        { name: 'pageview', url: request.original_url, domain: 'placecal.org' }.to_json,
        'Content-Type' => 'application/json',
        'User-Agent' => request.user_agent.to_s,
        'X-Forwarded-For' => request.remote_ip
      )
    rescue StandardError => e
      Rails.logger.warn("Plausible tracking failed: #{e.message}")
    end
  end
end
