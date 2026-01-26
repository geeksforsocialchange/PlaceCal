# frozen_string_literal: true

class ContainerWithHeaderComponentPreview < ViewComponent::Preview
  # @label Blue
  def blue
    render(ContainerWithHeaderComponent.new(title: 'Featured Events', color: 'blue')) do
      '<p>Content goes here</p>'.html_safe
    end
  end

  # @label Green
  def green
    render(ContainerWithHeaderComponent.new(title: 'Local Partners', color: 'green')) do
      '<p>Partner listings</p>'.html_safe
    end
  end

  # @label Red
  def red
    render(ContainerWithHeaderComponent.new(title: 'Important Notice', color: 'red')) do
      '<p>Alert content</p>'.html_safe
    end
  end
end
