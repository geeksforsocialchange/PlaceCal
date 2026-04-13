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
      data['address'] = {
        '@type' => 'PostalAddress',
        'streetAddress' => address.full_street_address,
        'addressLocality' => address.city,
        'postalCode' => address.postcode,
        'addressCountry' => address.country_code
      }.compact
    end

    build_json_ld_events(data, base_url) if base_url

    data
  end

  private

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
