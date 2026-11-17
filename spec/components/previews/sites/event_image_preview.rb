# frozen_string_literal: true

class Sites::EventImagePreview < Lookbook::Preview
  include PreviewSupport

  # @label Poster (portrait)
  # @notes Shown whole, never cropped, so the text on a poster stays readable.
  def poster
    render Components::Sites::EventImage.new(src: image("event-poster.jpg"), alt: "Spring Craft Fair")
  end

  # @label Photo (landscape)
  def photo
    render Components::Sites::EventImage.new(src: image("event-photo.jpg"), alt: "Walk in the park")
  end

  # @label On the event page
  # @notes The image sits above the description. An event without an image looks exactly as it does today.
  def on_the_event_page
    render EventPage.new(PreviewSupport.sample_event(summary: "Spring Craft Fair"), image("event-poster.jpg"))
  end

  # @label On the event page, landscape
  def on_the_event_page_landscape
    render EventPage.new(PreviewSupport.sample_event(summary: "Walk in the park"), image("event-photo.jpg"))
  end

  private

  def image(name) = ActionController::Base.helpers.image_path("lookbook/#{name}")

  # The event page's header, image and description, as Views::Sites::Events::Show lays them out
  class EventPage < Phlex::HTML
    def initialize(event, src)
      super()
      @event = event
      @src = src
    end

    def view_template
      render Components::Sites::Event.new(display_context: :page, event: @event, back: ["All events", "/events"])
      div(class: "container-narrowish mb-12 e-content") do
        render Components::Sites::EventImage.new(src: @src, alt: @event.summary)
        div(class: "markdown-content") { p { @event.description } }
      end
    end
  end
end
