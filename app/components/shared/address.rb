# frozen_string_literal: true

class Components::Shared::Address < Components::Base
  include Phlex::Rails::Helpers::Sanitize

  prop :address, _Nilable(::Address), default: nil
  prop :raw_location, _Nilable(String), default: nil

  def view_template
    p(class: 'place_info__address', property: 'address', typeof: 'PostalAddress') do
      sanitize(formatted_address)
    end
    render_directions_link if directions_url
  end

  private

  def formatted_address
    if @address.present?
      address_lines = @address.all_address_lines.map(&:strip)
      return address_lines.join(", #{view_context.tag.br}")
    end

    uri = URI.parse(@raw_location)
    "<a href='#{uri}'>#{uri.hostname}</a>"
  rescue URI::InvalidURIError
    @raw_location
  end

  # Apple Maps and OpenStreetMap only take coordinates, so without them Google stays the lone "Directions" link.
  def render_directions_link
    div(class: 'place_info__directions-list', role: 'group', aria_label: t('address.directions')) do
      a(href: directions_url, class: 'place_info__directions', target: '_blank', rel: 'noopener') do
        coordinates? ? t('address.google_maps') : t('address.directions')
      end
      next unless coordinates?

      whitespace
      a(href: "https://maps.apple.com/?daddr=#{coordinates}", class: 'place_info__directions-apple', target: '_blank', rel: 'noopener') do
        t('address.apple_maps')
      end
      whitespace
      a(href: "https://www.openstreetmap.org/directions?to=#{coordinates}", class: 'place_info__directions-osm', title: t('address.openstreetmap_full'), target: '_blank', rel: 'noopener') do
        t('address.openstreetmap')
      end
    end
  end

  # A Google Maps directions link, keyed on coordinates when we have them
  # (more precise than the geocoded street address) and falling back to the
  # postcode-bearing address text otherwise.
  def directions_url
    return unless @address.present? && (coordinates? || @address.postcode.present?)

    "https://www.google.com/maps/dir/?api=1&destination=#{destination_param}"
  end

  def coordinates?
    @address.latitude.present? && @address.longitude.present?
  end

  def coordinates
    "#{@address.latitude},#{@address.longitude}"
  end

  def destination_param
    return coordinates if coordinates?

    CGI.escape(@address.to_s)
  end
end
