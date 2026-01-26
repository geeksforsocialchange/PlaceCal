# frozen_string_literal: true

class StepsComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    steps = [
      { title: 'Step 1', description: 'Create your calendar' },
      { title: 'Step 2', description: 'Add your events' },
      { title: 'Step 3', description: 'Connect to PlaceCal' }
    ]
    render(StepsComponent.new(steps: steps))
  end

  # @label Custom Messages
  def custom_messages
    steps = [
      { title: 'Find', description: 'Search for local events' },
      { title: 'Connect', description: 'Meet your neighbours' },
      { title: 'Participate', description: 'Join community activities' }
    ]
    render(StepsComponent.new(
             steps: steps,
             start_message: "Feeling isolated? Don't know what's happening locally?",
             end_message: "Now you're connected to your community!"
           ))
  end
end
