# frozen_string_literal: true

# @display padding false
class Shared::HeroPreview < Lookbook::Preview
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

  # @label Listing page
  # @notes A theme fills the standfirst and its detail through locale keys.
  def listing
    render Components::Shared::Hero.new("Partners", "PlaceCal Hulme",
                                        standfirst: "Groups and venues near you",
                                        standfirst_detail: "Every partner here publishes their events on PlaceCal.")
  end

  # @label Record page with back link
  def record_page
    render Components::Shared::Hero.new("Repair Café", "PlaceCal Hulme", section: "Events", back: ["All events", "/events"])
  end

  # @label With schema property
  def with_schema
    render Components::Shared::Hero.new("Yoga for Beginners", nil, schema: "name")
  end
end
