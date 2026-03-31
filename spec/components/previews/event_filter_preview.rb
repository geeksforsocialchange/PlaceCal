# frozen_string_literal: true

class EventFilterPreview < Lookbook::Preview
  # @label Default
  # @notes Rendered without a site, so the neighbourhood filter is hidden.
  def default
    render Components::EventFilter.new(
      pointer: Time.zone.today,
      period: "day",
      sort: "time",
      repeating: "on",
      today_url: "/events",
      today: true
    )
  end

  # @label Weekly view (not today)
  def weekly_view
    render Components::EventFilter.new(
      pointer: Time.zone.today + 7.days,
      period: "week",
      sort: "time",
      repeating: "on",
      today_url: "/events",
      today: false
    )
  end
end
