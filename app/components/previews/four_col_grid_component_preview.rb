# frozen_string_literal: true

class FourColGridComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(FourColGridComponent.new) do
      <<-HTML.html_safe
        <div style="background: #eee; padding: 1rem;">Item 1</div>
        <div style="background: #eee; padding: 1rem;">Item 2</div>
        <div style="background: #eee; padding: 1rem;">Item 3</div>
        <div style="background: #eee; padding: 1rem;">Item 4</div>
      HTML
    end
  end

  # @label Partnership Cards (Larger)
  def partnership_cards
    render(FourColGridComponent.new(partnershipCards: true)) do
      <<-HTML.html_safe
        <div style="background: #eee; padding: 1rem;">Partnership 1</div>
        <div style="background: #eee; padding: 1rem;">Partnership 2</div>
        <div style="background: #eee; padding: 1rem;">Partnership 3</div>
        <div style="background: #eee; padding: 1rem;">Partnership 4</div>
      HTML
    end
  end
end
