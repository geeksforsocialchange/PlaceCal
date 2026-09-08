# frozen_string_literal: true

class HeroPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Shared::Hero.new("Community Events")
  end

  # @label Long title (triggers line break)
  def long_title
    render Components::Shared::Hero.new("Hulme and Moss Side Community Events Calendar")
  end

  # @label With subtitle
  def with_subtitle
    render Components::Shared::Hero.new("Events", "PlaceCal Hulme")
  end

  # @label With schema property
  def with_schema
    render Components::Shared::Hero.new("Yoga for Beginners", nil, "name")
  end
end
