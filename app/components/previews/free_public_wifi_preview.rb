# frozen_string_literal: true

class FreePublicWifiPreview < ViewComponent::Preview
  # @label Default
  def default
    places = [
      OpenStruct.new(name: 'Central Library', address: "St Peter's Square"),
      OpenStruct.new(name: 'Coffee Shop', address: '12 Market Street'),
      OpenStruct.new(name: 'Community Hub', address: '34 Oxford Road')
    ]
    render(FreePublicWifi.new(places))
  end

  # @label Single Location
  def single_location
    places = [
      OpenStruct.new(name: 'Public Library', address: '1 Main Street')
    ]
    render(FreePublicWifi.new(places))
  end
end
