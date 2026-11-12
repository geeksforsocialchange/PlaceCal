# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::OnlineEventButton, type: :phlex do
  def render_button(url, link_type: :direct, has_webpage: false)
    render_inline(described_class.new(online_address: OnlineAddress.new(url:, link_type:), has_webpage:))
  end

  it "names the meeting service on a direct link" do
    render_button("https://us02web.zoom.us/j/123")
    expect(page).to have_link("Join on Zoom", href: "https://us02web.zoom.us/j/123")
  end

  it "says watch for a streaming service" do
    render_button("https://www.youtube.com/live/abc")
    expect(page).to have_link("Watch on YouTube")
  end

  it "falls back to a generic join label for a direct link to an unknown host" do
    render_button("https://example.org/room")
    expect(page).to have_link("Join this meeting")
  end

  it "shows a direct link even when the event has a webpage link" do
    render_button("https://meet.google.com/abc", has_webpage: true)
    expect(page).to have_link("Join on Google Meet")
  end

  it "offers an indirect link as the webpage when the event has none" do
    render_button("https://www.eventbrite.co.uk/e/123", link_type: :indirect)
    expect(page).to have_link("Visit the webpage for this event")
  end

  it "shows nothing for an indirect link when the event has a webpage link" do
    render_button("https://www.eventbrite.co.uk/e/123", link_type: :indirect, has_webpage: true)
    expect(page).to have_no_link
  end
end
