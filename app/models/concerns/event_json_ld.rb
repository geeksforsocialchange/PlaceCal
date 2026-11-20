# frozen_string_literal: true

module EventJsonLd
  extend ActiveSupport::Concern

  def to_json_ld(base_url:, organiser_base_url: base_url)
    event_url = "#{base_url}/events/#{id}"
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Event',
      '@id' => event_url,
      'name' => summary,
      'startDate' => dtstart.in_time_zone('Europe/London').iso8601,
      'url' => event_url,
      'eventStatus' => json_ld_event_status
    }

    data['endDate'] = dtend.in_time_zone('Europe/London').iso8601 if dtend
    data['description'] = ActionController::Base.helpers.strip_tags(description_html).presence if description_html.present?
    data['eventAttendanceMode'] = json_ld_attendance_mode

    build_json_ld_location(data)
    build_json_ld_image(data)
    build_json_ld_organizer(data, organiser_base_url)
    build_json_ld_offers(data)
    build_json_ld_event_series(data, event_url)

    data
  end

  JSON_LD_STATUSES = { 'cancelled' => 'https://schema.org/EventCancelled', 'postponed' => 'https://schema.org/EventPostponed' }.freeze

  def json_ld_event_status
    JSON_LD_STATUSES.fetch(status, 'https://schema.org/EventScheduled')
  end

  def json_ld_attendance_mode
    if address && online_address
      'https://schema.org/MixedEventAttendanceMode'
    elsif online_address
      'https://schema.org/OnlineEventAttendanceMode'
    else
      'https://schema.org/OfflineEventAttendanceMode'
    end
  end

  private

  def build_json_ld_image(data)
    image_partner = [organiser, partner_at_location].compact.find(&:image?)
    data['image'] = image_partner.image.url if image_partner
  end

  def build_json_ld_location(data)
    # Skip address fallback for online-only and no-location events
    skip_fallback = !address && (online_address || %w[no_location online_only].include?(calendar&.strategy))
    location_address = skip_fallback ? nil : resolved_address

    if location_address
      location = {
        '@type' => 'Place',
        'name' => partner_at_location&.name,
        'address' => location_address.to_json_ld
      }.compact

      if location_address.latitude && location_address.longitude
        location['geo'] = {
          '@type' => 'GeoCoordinates',
          'latitude' => location_address.latitude,
          'longitude' => location_address.longitude
        }
      end

      data['location'] = location
    elsif online_address
      data['location'] = {
        '@type' => 'VirtualLocation',
        'url' => online_address.url
      }
    end
  end

  def build_json_ld_organizer(data, base_url)
    return unless organiser

    page_url = "#{base_url}/partners/#{organiser.to_param}"

    data['organizer'] = {
      '@type' => 'Organization',
      '@id' => page_url,
      'name' => organiser.name,
      'url' => organiser.url.presence || page_url
    }
  end

  # An unknown sold_out is stated as InStock
  def build_json_ld_offers(data)
    url = ticket_url.presence || publisher_url
    return if url.blank?

    data['offers'] = {
      '@type' => 'Offer',
      'url' => url,
      'availability' => sold_out ? 'https://schema.org/SoldOut' : 'https://schema.org/InStock',
      'price' => price_from && format('%.2f', price_from),
      'priceCurrency' => price_currency.presence
    }.compact
  end

  def build_json_ld_event_series(data, event_url)
    return if rrule.blank?

    data['superEvent'] = {
      '@type' => 'EventSeries',
      '@id' => "#{event_url}#series",
      'name' => summary
    }
  end
end
