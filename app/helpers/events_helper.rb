# frozen_string_literal: true

module EventsHelper
  def options_for_events
    Event.all.collect { |e| [e.summary, e.id] }
  end
end
