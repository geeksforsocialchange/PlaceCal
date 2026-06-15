# frozen_string_literal: true

# Resolves an event's online meeting link to an OnlineAddress record.
#
# PanCal reports online meeting links (Zoom, Google Meet, Jitsi, etc.) as a
# plain URL string; persisting it is PlaceCal's job.
class CalendarImporter::OnlineDetector
  def initialize(event_data)
    @event_data = event_data
  end

  # @return [Integer, nil] id of the OnlineAddress for the event's online
  #   link, or nil when the event has none
  def detect
    url = event_data.online_meeting_url
    return if url.blank?

    OnlineAddress.find_or_create_by(url: url, link_type: link_type_for(url)).id
  end

  private

  attr_reader :event_data

  # Links straight into a meeting/stream are 'direct'; links to an event
  # webpage (e.g. an Eventbrite online event) are 'indirect'
  def link_type_for(url)
    direct = PanCal::Event::ONLINE_MEETING_DOMAINS.any? { |domain| url.include?(domain) }
    direct ? 'direct' : 'indirect'
  end
end
