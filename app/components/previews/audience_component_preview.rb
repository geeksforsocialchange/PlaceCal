# frozen_string_literal: true

class AudienceComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(AudienceComponent.new(
             title: 'Community Members',
             image: 'home/audience-community.jpg',
             image_alt: 'People at a community gathering',
             body: 'Find events and activities happening in your neighbourhood.',
             link: '/events'
           ))
  end

  # @label Without Link
  def without_link
    render(AudienceComponent.new(
             title: 'Local Partners',
             image: 'home/audience-partners.jpg',
             image_alt: 'Community organisation staff meeting',
             body: 'Connect with local organisations running events in your area.'
           ))
  end
end
