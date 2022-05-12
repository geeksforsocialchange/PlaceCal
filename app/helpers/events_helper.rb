# frozen_string_literal: true

module EventsHelper
  def options_for_events
    Event.all.collect { |e| [e.summary, e.id] }
  end

  def event_link(event)
    return if @event.publisher_url.blank?

    link_to(
      'Event Page',
      event.publisher_url,
      class: 'btn btn-primary'
    ).html_safe
  end
end
