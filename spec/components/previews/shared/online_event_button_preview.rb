# frozen_string_literal: true

# @notes The online link button on an event page. It sits beside "Visit the webpage for this event" when the event has one.
class Shared::OnlineEventButtonPreview < Lookbook::Preview
  # @label Every online link
  # @notes A direct link to a known host names it; an indirect link only shows when the event has no webpage link.
  def every_link
    render ButtonList.new(OnlinePreviewSupport::URLS.transform_values { OnlinePreviewSupport.address(it) })
  end

  # @label Meeting link (Zoom)
  def meeting
    render Components::Shared::OnlineEventButton.new(online_address: OnlinePreviewSupport.address("https://us02web.zoom.us/j/123"))
  end

  # @label Stream link (YouTube)
  def stream
    render Components::Shared::OnlineEventButton.new(online_address: OnlinePreviewSupport.address("https://www.youtube.com/live/abc"))
  end

  # @label Direct link to an unknown host
  def unknown_direct
    online_address = OnlinePreviewSupport.address("https://example.org/room", link_type: :direct)
    render Components::Shared::OnlineEventButton.new(online_address:)
  end

  # @label Webpage link, event has no other webpage
  def indirect
    render Components::Shared::OnlineEventButton.new(online_address: OnlinePreviewSupport.address("https://www.eventbrite.co.uk/e/123"))
  end

  class ButtonList < Phlex::HTML
    def initialize(addresses)
      super()
      @addresses = addresses
    end

    def view_template
      dl(class: "grid grid-cols-[auto_1fr] gap-x-6 gap-y-3 items-center text-sm text-foreground") do
        @addresses.each do |name, online_address|
          dt { name }
          dd { render Components::Shared::OnlineEventButton.new(online_address:) }
        end
      end
    end
  end
end
