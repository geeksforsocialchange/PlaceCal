# frozen_string_literal: true

class HeroSectionComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(HeroSectionComponent.new(
             image_path: 'home/hero-image.jpg',
             image_credit: 'Photo by Jane Smith',
             title: 'The Community Calendar',
             alttext: 'People gathering at a community event'
           ))
  end

  # @label Without Title
  def without_title
    render(HeroSectionComponent.new(
             image_path: 'home/hero-image.jpg',
             image_credit: 'Photo by John Doe',
             title: nil,
             alttext: 'Neighbours chatting at a street party'
           ))
  end
end
