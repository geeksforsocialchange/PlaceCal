# frozen_string_literal: true

class StepsPreview < Lookbook::Preview
  # @label Default
  def default
    steps = [
      { id: "1", image_alt: "Step 1: Sign up", content: "<p><strong>Step 1:</strong> Sign up and tell us about your organisation.</p>" },
      { id: "2", image_alt: "Step 2: Connect calendar", content: "<p><strong>Step 2:</strong> Connect your existing online calendar.</p>" },
      { id: "3", image_alt: "Step 3: Go live", content: "<p><strong>Step 3:</strong> Your events appear on PlaceCal automatically.</p>" }
    ]
    render Components::Steps.new(steps: steps)
  end
end
