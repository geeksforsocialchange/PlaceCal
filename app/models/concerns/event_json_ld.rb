# frozen_string_literal: true

module EventJsonLd
  extend ActiveSupport::Concern

  def to_json_ld(base_url:)
    event_url = "#{base_url}/events/#{id}"
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Event',
      '@id' => event_url,
      'name' => summary,
      'startDate' => dtstart.iso8601,
      'url' => event_url,
      'eventStatus' => 'https://schema.org/EventScheduled'
    }

    data['endDate'] = dtend.iso8601 if dtend
    data['description'] = ActionController::Base.helpers.strip_tags(description_html).presence if description_html.present?

    build_json_ld_location(data)
    build_json_ld_organizer(data, base_url)
    build_json_ld_offers(data)
    build_json_ld_event_series(data, event_url)

    data
  end

  private

  def build_json_ld_location(data)
    if address
      location = {
        '@type' => 'Place',
        'name' => partner_at_location&.name,
        'address' => {
          '@type' => 'PostalAddress',
          'streetAddress' => address.full_street_address,
          'addressLocality' => address.city,
          'postalCode' => address.postcode,
          'addressCountry' => address.country_code
        }.compact
      }.compact

      if address.latitude && address.longitude
        location['geo'] = {
          '@type' => 'GeoCoordinates',
          'latitude' => address.latitude,
          'longitude' => address.longitude
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
    return unless partner

    data['organizer'] = {
      '@type' => 'Organization',
      '@id' => "#{base_url}/partners/#{partner.to_param}",
      'name' => partner.name,
      'url' => partner.url
    }.compact
  end

  def build_json_ld_offers(data)
    return if publisher_url.blank?

    data['offers'] = {
      '@type' => 'Offer',
      'url' => publisher_url,
      'availability' => 'https://schema.org/InStock'
    }
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
