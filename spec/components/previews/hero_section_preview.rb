# frozen_string_literal: true

class HeroSectionPreview < Lookbook::Preview
  # @label Default (no image)
  def default
    render Components::HeroSection.new
  end

  # @label With image and credit
  def with_image
    render Components::HeroSection.new(
      image_path: "https://placekitten.com/1200/400",
      image_credit: "Photo by Example Photographer",
      alttext: "A community centre in Hulme"
    )
  end

  # @label With custom title
  def with_custom_title
    render Components::HeroSection.new(
      title: "Connecting communities through shared calendars"
    )
  end
end
