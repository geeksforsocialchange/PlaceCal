# frozen_string_literal: true

class ComputerAccessPreview < ViewComponent::Preview
  # @label Default
  def default
    places = [
      OpenStruct.new(name: 'Hulme Library', address: '123 High Street'),
      OpenStruct.new(name: 'Community Centre', address: '45 Main Road'),
      OpenStruct.new(name: 'Youth Club', address: '78 Park Lane')
    ]
    render(ComputerAccess.new(places))
  end

  # @label Single Location
  def single_location
    places = [
      OpenStruct.new(name: 'Local Library', address: '1 Library Street')
    ]
    render(ComputerAccess.new(places))
  end
end
