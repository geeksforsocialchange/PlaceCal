# frozen_string_literal: true

# @display width page
class Sites::EventRowsPreview < Lookbook::Preview
  include PreviewSupport

  # @label List of events
  # @notes As on a partner page's Upcoming events and an event page's More from, on a site that shows neighbourhoods.
  def list
    render Components::Sites::EventRows.new(events: sample_events, show_neighbourhoods: true)
  end

  # @label Without neighbourhoods
  # @notes A site that doesn't show neighbourhoods.
  def without_neighbourhoods
    render Components::Sites::EventRows.new(events: sample_events)
  end

  # @label Every detail
  def every_detail
    render Components::Sites::EventRows.new(events: [PreviewSupport.sample_full_event], show_neighbourhoods: true)
  end

  # @label Online services
  # @notes Known meeting and streaming hosts are named; anything else says "Online".
  def online_services
    render Components::Sites::EventRows.new(events: OnlinePreviewSupport.events)
  end

  private

  def sample_events
    hulme = NeighbourhoodMock.new(name: "Hulme")
    moss_side = NeighbourhoodMock.new(name: "Moss Side")
    [
      PreviewSupport.sample_event(summary: "Storytelling Evening", neighbourhood: hulme),
      PreviewSupport.sample_event(id: 2, summary: "Art Exhibition Opening", neighbourhood: moss_side,
                                  online_address: OnlinePreviewSupport.address("https://example.org/live")),
      PreviewSupport.sample_repeating_event.tap { it.neighbourhood = hulme },
      PreviewSupport.sample_event(id: 4, summary: "Film Screening and Discussion", neighbourhood: moss_side)
    ]
  end
end
