# frozen_string_literal: true

# Determines online address for an event from its data.
#
# Checks for online meeting links (Zoom, Google Meet, Jitsi, etc.)
# in event description and custom properties.
class CalendarImporter::OnlineDetector
  def initialize(event_data)
    @event_data = event_data
  end

  # Sets online_address_id on event_data if an online link is found
  def detect
    event_data.online_address_id = event_data.online_event_id
  end

  private

  attr_reader :event_data
end
