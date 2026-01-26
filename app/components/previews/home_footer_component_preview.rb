# frozen_string_literal: true

class HomeFooterComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(HomeFooterComponent.new)
  end
end
