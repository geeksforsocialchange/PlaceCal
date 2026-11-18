# frozen_string_literal: true

class Sites::EventListPreview < Lookbook::Preview
  # @label With events
  def with_events
    render Components::Sites::EventList.new(events: PreviewSupport.sample_events_by_day)
  end

  # @label With events already on
  # @notes A partner page lists long-running events already on once, above the days.
  def with_ongoing
    render Components::Sites::EventList.new(events: PreviewSupport.sample_events_by_day, ongoing: [LongRunningPreviewSupport.event])
  end

  # @label Cut short
  def truncated
    render Components::Sites::EventList.new(events: PreviewSupport.sample_events_by_day, truncated: true)
  end

  # @label Empty state
  def empty
    render Components::Sites::EventList.new(events: {})
  end
end
