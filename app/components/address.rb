# frozen_string_literal: true

class Components::Address < Components::Base
  include Phlex::Rails::Helpers::Sanitize

  prop :address, _Nilable(_Any), default: nil
  prop :raw_location, _Nilable(String), default: nil

  def view_template
    p(class: 'place_info__address', property: 'address', typeof: 'PostalAddress') do
      sanitize(formatted_address)
    end
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
end
