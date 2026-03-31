# frozen_string_literal: true

class EventListPreview < Lookbook::Preview
  # @label With events
  def with_events
    render Components::EventList.new(events: PreviewSupport.sample_events_by_day)
  end

  # @label Empty state
  def empty
    render Components::EventList.new(events: {})
  end
end
