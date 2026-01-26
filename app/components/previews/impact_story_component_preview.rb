# frozen_string_literal: true

class ImpactStoryComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(ImpactStoryComponent.new(
             title: 'Connecting Communities',
             image: 'home/impact-story.jpg',
             image_caption: 'A community event in Hulme'
           )) do
      '<p>PlaceCal has helped hundreds of people find local events and connect with their neighbours.</p>'.html_safe
    end
  end
end
