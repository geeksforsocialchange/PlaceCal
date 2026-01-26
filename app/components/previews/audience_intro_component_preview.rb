# frozen_string_literal: true

class AudienceIntroComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(AudienceIntroComponent.new(
             title: 'Who is PlaceCal for?',
             subtitle: 'PlaceCal helps connect communities with local events and services',
             image: 'home/intro-image.jpg',
             image_alt: 'Diverse group of community members'
           ))
  end
end
