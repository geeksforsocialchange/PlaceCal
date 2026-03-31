# frozen_string_literal: true

class DetailsPreview < Lookbook::Preview
  # @label Default (image right)
  def default
    render Components::Details.new(
      header: "About this event",
      summary: "<p>A weekly coffee morning for local residents. Tea, coffee, and biscuits provided.</p>",
      image_url: "https://placekitten.com/400/300",
      image_alt: "Community centre interior",
      image_layout: "right"
    ) { "Additional details about the event go here." }
  end

  # @label Image left
  def image_left
    render Components::Details.new(
      header: "Our story",
      summary: "<p>PlaceCal was born from a simple idea: what if there was one place to find everything happening in your neighbourhood?</p>",
      image_url: "https://placekitten.com/400/300",
      image_alt: "Team photo",
      image_layout: "left"
    ) { "We started in Hulme and Moss Side, Manchester." }
  end

  # @label Image center
  def image_center
    render Components::Details.new(
      header: "How it works",
      summary: "<p>Organisations add their calendars. PlaceCal does the rest.</p>",
      image_url: "https://placekitten.com/800/300",
      image_alt: "Diagram showing how PlaceCal works",
      image_layout: "center"
    ) { "It really is that simple." }
  end

  # @label No image
  def no_image
    render Components::Details.new(
      header: "Privacy Policy",
      summary: "<p>We take your privacy seriously. PlaceCal does not track you or sell your data.</p>",
      image_url: nil,
      image_alt: "",
      image_layout: "none"
    ) { "Read our full privacy policy for more details." }
  end
end
