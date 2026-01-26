# frozen_string_literal: true

class HomeStraplineComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(HomeStraplineComponent.new)
  end
end
