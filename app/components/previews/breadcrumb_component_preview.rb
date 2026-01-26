# frozen_string_literal: true

class BreadcrumbComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(BreadcrumbComponent.new(
             trail: [['Events', '/events'], ['Today', '/events/2024/1/15']],
             site_name: 'PlaceCal Manchester'
           ))
  end

  # @label Single Level
  def single_level
    render(BreadcrumbComponent.new(
             trail: [['Partners', '/partners']],
             site_name: 'The Community Calendar'
           ))
  end

  # @label Deep Nesting
  def deep_nesting
    render(BreadcrumbComponent.new(
             trail: [
               ['Events', '/events'],
               ['January', '/events/2024/1'],
               ['Week 3', '/events/2024/1/15']
             ],
             site_name: 'Hulme Events'
           ))
  end
end
