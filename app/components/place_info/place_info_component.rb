# frozen_string_literal: true

# app/components/place/place_info_component.rb
class PlaceInfoComponent < MountainView::Presenter
  property :phone, default: false
  property :url, default: false
  property :name, default: false
  property :address, default: false
  property :email, default: false

  def formatted_url
    url = properties[:url]
    url ? strip_url(url) : false
  end

  def contact?
    phone || email || url
  end

  private

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub('/', '/ ')
  end
end
