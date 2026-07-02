# frozen_string_literal: true

# Chrome and cards for the join marketing site (join.placecal.org, #3163).
# This namespace is only possible because the enquiry form model is named
# ContactRequest — a top-level Join model would be shadowed by this module
# inside every view that includes the Components kit.
class Components::Join::Base < Components::Base
  # Ordered audience registry: key → square card image. One "Who it's for"
  # page each; keys mirror the join.audiences.* locale tree. Keeping the image
  # beside the key means an audience can't exist without card artwork.
  AUDIENCES = {
    'community_groups' => 'home/audiences/communities_square.jpg',
    'metropolitan_areas' => 'home/audiences/metro_square.jpg',
    'housing_providers' => 'home/audiences/housing_square.jpg',
    'social_prescribers' => 'home/audiences/social_square.jpg',
    'vcses' => 'home/audiences/vcses_square.jpg',
    'culture_tourism' => 'home/audiences/culture_square.jpg'
  }.freeze
  AUDIENCE_KEYS = AUDIENCES.keys.freeze
  AUDIENCE_SLUGS = AUDIENCE_KEYS.map { |key| key.tr('_', '-') }.freeze

  private

  # Absolute URL of the apex (the nationwide directory) from the join
  # subdomain, e.g. https://placecal.org or http://lvh.me:3000.
  def apex_url
    "#{request.protocol}#{request.domain}#{request.port_string}"
  end

  def audience_path(key)
    join_audience_path(key.tr('_', '-'))
  end
end
