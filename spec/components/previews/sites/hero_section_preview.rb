# frozen_string_literal: true

# @display padding false
class Sites::HeroSectionPreview < Lookbook::Preview
  # @label Default (no image)
  def default
    render Components::Sites::HeroSection.new
  end

  # @label With image and credit
  def with_image
    render Components::Sites::HeroSection.new(
      image_path: ActionController::Base.helpers.image_path("hero-image-default.jpg"),
      image_credit: "Photo by Example Photographer",
      alttext: "A community centre in Hulme"
    )
  end

  # @label With custom title
  def with_custom_title
    render Components::Sites::HeroSection.new(
      title: "Connecting communities through shared calendars"
    )
  end
end
