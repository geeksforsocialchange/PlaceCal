# frozen_string_literal: true

class LinkBtnLrgComponentPreview < ViewComponent::Preview
  # @label Light (Default)
  def light
    render(LinkBtnLrgComponent.new(link_url: '/events', color: 'light')) do
      'View Events'
    end
  end

  # @label Green
  def green
    render(LinkBtnLrgComponent.new(link_url: '/join', color: 'green')) do
      'Join PlaceCal'
    end
  end

  # @label Pink
  def pink
    render(LinkBtnLrgComponent.new(link_url: '/contact', color: 'pink')) do
      'Contact Us'
    end
  end
end
