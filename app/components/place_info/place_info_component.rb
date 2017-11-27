# frozen_string_literal: true

# app/components/place/place_info_component.rb
class PlaceInfoComponent < MountainView::Presenter
  properties :phone, :email, :url, :name, :address

  def phone
    properties[:phone] || false
  end

  def name
    properties[:name] || false
  end

  def email
    properties[:email] || false
  end

  def url
    properties[:url] || false
  end

  def address
    properties[:address] || false
  end

  def contact?
    phone || email || url
  end
end
