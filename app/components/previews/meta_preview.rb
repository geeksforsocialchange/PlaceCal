# frozen_string_literal: true

class MetaPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Meta.new('/events/2024/1/15'))
  end

  # @label With Link Slot
  def with_link
    render(Meta.new('/partners/community-centre')) do |component|
      component.with_link do
        '<a href="/partners">Back to Partners</a>'.html_safe
      end
    end
  end
end
