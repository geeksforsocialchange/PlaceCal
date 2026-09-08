# frozen_string_literal: true

class Components::Address < Components::Base
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

  def render_directions_link
    a(href: directions_url, class: 'place_info__directions', target: '_blank', rel: 'noopener') do
      t('address.directions')
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

  def destination_param
    return "#{@address.latitude},#{@address.longitude}" if coordinates?

    CGI.escape(@address.to_s)
  end
end
