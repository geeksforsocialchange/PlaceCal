# frozen_string_literal: true

# Finds the importable calendar behind an Eventbrite event link or a Luma page, or nil.
module CalendarSourceResolver
  Result = Data.define(:kind, :source)

  EVENTBRITE_EVENT = %r{\Ahttps?://www\.eventbrite\.(com|co\.uk)/e/(?:[^/?#]*-)?(\d+)/?(?:[?#]|\z)}
  LUMA_PAGE = %r{\Ahttps?://(?:www\.)?(?:lu\.ma|luma\.com)/([A-Za-z0-9_-]+)/?(?:[?#]|\z)}
  LUMA_CALENDAR_ID = /\Acal-[A-Za-z0-9]+\z/
  # An admin is waiting on the form, so lookups give up quickly rather than retrying
  TIMEOUT = 5

  module_function

  # @param url [String]
  # @return [Result, nil]
  def call(url)
    url = url.to_s.strip
    if (match = EVENTBRITE_EVENT.match(url))
      eventbrite_organiser(match[1], match[2])
    elsif (match = LUMA_PAGE.match(url))
      luma_calendar(match[1])
    end
  rescue StandardError => e
    Rails.logger.warn("Calendar source lookup failed for #{url}: #{e.class} (#{e.message})")
    nil
  end

  def eventbrite_organiser(tld, event_id)
    token = ENV.fetch('EVENTBRITE_TOKEN', nil)
    return if token.blank?

    response = HTTParty.get("#{CalendarImporter::Parsers::Eventbrite::API_BASE_URL}/events/#{event_id}/",
                            headers: { 'Authorization' => "Bearer #{token}" }, timeout: TIMEOUT)
    return unless response.success?

    organizer_id = JSON.parse(response.body)['organizer_id'].to_s
    return unless organizer_id.match?(/\A\d+\z/)

    Result.new(kind: 'eventbrite', source: "https://www.eventbrite.#{tld}/o/#{organizer_id}")
  end

  def luma_calendar(slug)
    url = "https://api.lu.ma/url?url=#{CGI.escape(slug)}"
    OutboundUrlGuard.vet!(url)
    response = HTTParty.get(url, timeout: TIMEOUT, follow_redirects: false)
    return unless response.success?

    body = JSON.parse(response.body)
    return unless %w[calendar event].include?(body['kind'])

    calendar = body.dig('data', 'calendar') || {}
    # Events hosted by a person sit on their personal calendar, not a group's
    return if calendar['is_personal']

    id = calendar['api_id'].to_s
    return unless LUMA_CALENDAR_ID.match?(id)

    Result.new(kind: 'luma', source: "https://api.lu.ma/ics/get?entity=calendar&id=#{id}")
  end
end
