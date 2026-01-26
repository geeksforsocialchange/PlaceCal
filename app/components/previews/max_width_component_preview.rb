# frozen_string_literal: true

class MaxWidthComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(MaxWidthComponent.new) do
      '<p>This content is constrained to maximum width.</p>'.html_safe
    end
  end
end
