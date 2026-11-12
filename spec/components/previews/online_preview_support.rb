# frozen_string_literal: true

# Online addresses for Lookbook previews, one per kind of link the event pages handle.
module OnlinePreviewSupport
  module_function

  URLS = {
    "Google Meet" => "https://meet.google.com/abc-defg-hij",
    "Zoom, on a regional subdomain" => "https://us02web.zoom.us/j/123456789",
    "Microsoft Teams" => "https://teams.microsoft.com/l/meetup-join/123",
    "Discord" => "https://discord.gg/abc123",
    "YouTube" => "https://www.youtube.com/live/abc123",
    "Instagram" => "https://www.instagram.com/placecal/live",
    "Unknown host" => "https://example.org/live",
    "Eventbrite page" => "https://www.eventbrite.co.uk/e/123"
  }.freeze

  # Unsaved, with link_type set the way the importer would set it.
  def address(url, link_type: OnlineAddress.service_for(url) ? :direct : :indirect)
    OnlineAddress.new(url:, link_type:)
  end

  def events
    URLS.each_with_index.map do |(name, url), index|
      PreviewSupport.sample_event(id: index + 10, summary: name, online_address: address(url), address: nil)
    end
  end
end
