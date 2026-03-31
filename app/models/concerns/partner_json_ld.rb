# frozen_string_literal: true

module PartnerJsonLd
  extend ActiveSupport::Concern

  def to_json_ld
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Organization',
      'name' => name
    }
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

    data
  end
end
