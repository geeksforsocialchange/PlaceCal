# frozen_string_literal: true

class HeroComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(HeroComponent.new('Community Events', "Find what's happening near you"))
  end

  # @label Short Title
  def short_title
    render(HeroComponent.new('Events'))
  end

  # @label Long Title (Auto-wrapped)
  def long_title
    render(HeroComponent.new(
             'Welcome to Hulme and Moss Side Community Calendar',
             'Connecting neighbours through local events'
           ))
  end

  # @label With Schema
  def with_schema
    schema = { '@context' => 'https://schema.org', '@type' => 'WebPage' }
    render(HeroComponent.new('Partners Directory', 'Local organisations', schema))
  end
end
