# frozen_string_literal: true

# A top-level Join model would be shadowed by this namespace in every view.
class Components::Join::Base < Components::Base
  # Ordered: audience key to card image, so none exists without artwork.
  AUDIENCES = {
    'community_groups' => 'home/audiences/communities_square.jpg',
    'metropolitan_areas' => 'home/audiences/metro_square.jpg',
    'housing_providers' => 'home/audiences/housing_square.jpg',
    'social_prescribers' => 'home/audiences/social_square.jpg',
    'vcses' => 'home/audiences/vcses_square.jpg',
    'culture_tourism' => 'home/audiences/culture_square.jpg'
  }.freeze
  AUDIENCE_KEYS = AUDIENCES.keys.freeze
  def self.slug_for(key) = key.tr('_', '-')

  AUDIENCE_SLUGS = AUDIENCE_KEYS.map { |key| slug_for(key) }.freeze

  private

  # Absolute URL of the apex (the nationwide directory) from the join
  # subdomain, e.g. https://placecal.org or http://lvh.me:3000.
  def apex_url
    "#{request.protocol}#{request.domain}#{request.port_string}"
  end

  def audience_path(key)
    join_audience_path(self.class.slug_for(key))
  end
end
