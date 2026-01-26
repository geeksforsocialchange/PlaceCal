# frozen_string_literal: true

class HelpAddingEventsPreview < ViewComponent::Preview
  # @label Default
  def default
    site = OpenStruct.new(
      name: 'PlaceCal Manchester',
      slug: 'manchester',
      tagline: 'A community calendar for Manchester'
    )
    render(HelpAddingEvents.new(site))
  end
end
