# frozen_string_literal: true

class HeroPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Hero.new("Community Events")
  end

  # @label Long title (triggers line break)
  def long_title
    render Components::Hero.new("Hulme and Moss Side Community Events Calendar")
  end

  # @label With subtitle
  def with_subtitle
    render Components::Hero.new("Events", "PlaceCal Hulme")
  end

  # @label With schema property
  def with_schema
    render Components::Hero.new("Yoga for Beginners", nil, "name")
  end
end
