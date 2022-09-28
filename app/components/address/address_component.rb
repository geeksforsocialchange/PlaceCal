# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class AddressComponent < MountainView::Presenter
  property :address

  def formatted_address
    return if address.blank?

    address.all_address_lines.map(&:strip).join(", <br>").html_safe
  end
end
