# frozen_string_literal: true

class Sites::EventFilterPreview < Lookbook::Preview
  # @label Default
  # @notes Rendered without a site, so the neighbourhood filter is hidden.
  def default
    render Components::Sites::EventFilter.new(
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
    render Components::Sites::EventFilter.new(
      pointer: Time.zone.today + 7.days,
      period: "week",
      sort: "time",
      repeating: "on",
      today_url: "/events",
      today: false
    )
  end

  # @label Day strip with date picker, filters applied
  # @notes A theme that sets event_filter_style :day_strip_with_date_picker, as Trans Dimension does, on tomorrow sorted by name.
  def day_strip_with_filters_applied
    Current.theme = PlaceCal::Theme.new(:preview).tap { |theme| theme.event_filter_style :day_strip_with_date_picker }
    render Components::Sites::EventFilter.new(
      pointer: Time.zone.today + 1.day,
      period: "day",
      sort: "summary",
      repeating: "off",
      today_url: "/events",
      today: false
    )
  end
end
