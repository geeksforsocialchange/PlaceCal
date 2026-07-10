# frozen_string_literal: true

module PartnerJsonLd
  extend ActiveSupport::Concern

  def to_json_ld(base_url: nil)
    partner_url = "#{base_url}/partners/#{to_param}" if base_url

    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Organization',
      'name' => name
    }
    data['@id'] = partner_url if partner_url
    data['url'] = url if url.present?

    data['description'] = ActionController::Base.helpers.strip_tags(summary).presence if summary.present?
    data['telephone'] = public_phone if public_phone.present?
    data['email'] = public_email if public_email.present?
    data['image'] = image.url if image?

    same_as = [twitter_url, instagram_url]
    same_as << "https://facebook.com/#{facebook_link}" if facebook_link.present?
    same_as = same_as.compact
    data['sameAs'] = same_as if same_as.any?

    if address
      postal_address = {
        '@type' => 'PostalAddress',
        'streetAddress' => address.full_street_address,
        'addressLocality' => address.city,
        'postalCode' => address.postcode,
        'addressCountry' => address.country_code
      }.compact
      data['address'] = postal_address
      build_json_ld_location(data, postal_address)
    end

    build_json_ld_events(data, base_url) if base_url

    data
  end

  private

  # Partners are all kinds of thing (charities, groups, council services,
  # libraries), so the org itself stays a generic Organization. The physical
  # venue signals — geo + opening hours — hang off a `location` Place, which
  # carries no "business" connotation and is what Google reads for local
  # results. Only emitted when the partner has an address.
  def build_json_ld_location(data, postal_address)
    place = { '@type' => 'Place', 'address' => postal_address }

    if address.latitude && address.longitude
      place['geo'] = {
        '@type' => 'GeoCoordinates',
        'latitude' => address.latitude,
        'longitude' => address.longitude
      }
    end

    hours = json_ld_opening_hours
    place['openingHoursSpecification'] = hours if hours.any?

    data['location'] = place
  end

  # Maps the stored opening_times (already schema.org-shaped) into an
  # OpeningHoursSpecification array, normalising the day to a plain name and
  # times to HH:MM.
  def json_ld_opening_hours
    parsed = JSON.parse(opening_times_data)
    return [] unless parsed.is_a?(Array)

    parsed.filter_map do |slot|
      day = slot['dayOfWeek']
      opens = Time.zone.parse(slot['opens'].to_s)
      closes = Time.zone.parse(slot['closes'].to_s)
      next if day.blank? || opens.nil? || closes.nil?

      {
        '@type' => 'OpeningHoursSpecification',
        'dayOfWeek' => day.split('/').last,
        'opens' => opens.strftime('%H:%M'),
        'closes' => closes.strftime('%H:%M')
      }
    end
  rescue JSON::ParserError
    []
  end

  def build_json_ld_events(data, base_url)
    upcoming = events.upcoming.sort_by_time.limit(10)
    return unless upcoming.any?

    data['event'] = upcoming.map do |event|
      entry = {
        '@type' => 'Event',
        '@id' => "#{base_url}/events/#{event.id}",
        'name' => event.summary,
        'startDate' => event.dtstart.in_time_zone('Europe/London').iso8601,
        'eventStatus' => 'https://schema.org/EventScheduled',
        'eventAttendanceMode' => event.json_ld_attendance_mode
      }
      entry['endDate'] = event.dtend.in_time_zone('Europe/London').iso8601 if event.dtend
      entry['description'] = ActionController::Base.helpers.strip_tags(event.description_html).presence if event.description_html.present?
      if event.address
        entry['location'] = {
          '@type' => 'Place',
          'name' => event.partner_at_location&.name,
          'address' => {
            '@type' => 'PostalAddress',
            'streetAddress' => event.address.full_street_address,
            'addressLocality' => event.address.city,
            'postalCode' => event.address.postcode,
            'addressCountry' => event.address.country_code
          }.compact
        }
      end
      entry
    end
  end
end
