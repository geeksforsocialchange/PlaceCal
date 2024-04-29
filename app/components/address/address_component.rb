# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class AddressComponent < MountainView::Presenter
  property :address
  property :raw_location

  def formatted_address
    if address.present?

      address_lines = address.all_address_lines.map(&:strip)
      return address_lines.join(', <br>').html_safe
    end

    uri = URI.parse(raw_location)
    "<a href='#{uri}'>#{uri.hostname}</a>".html_safe

  rescue URI::InvalidURIError
    raw_location
  end
end
