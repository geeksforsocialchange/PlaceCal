# frozen_string_literal: true

class PullQuoteComponentPreview < ViewComponent::Preview
  # @label Dark Mode
  def dark_mode
    render(PullQuoteComponent.new(
             source: 'Community member',
             context: 'Hulme resident',
             options: { light_mode: false }
           )) do
      'PlaceCal has completely changed how I find out about events in my neighbourhood.'
    end
  end

  # @label Light Mode
  def light_mode
    render(PullQuoteComponent.new(
             source: 'Partner organisation',
             context: 'Local charity',
             options: { light_mode: true }
           )) do
      'Since joining PlaceCal, attendance at our events has increased significantly.'
    end
  end
end
