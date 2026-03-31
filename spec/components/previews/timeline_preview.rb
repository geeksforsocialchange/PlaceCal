# frozen_string_literal: true

class TimelinePreview < Lookbook::Preview
  # @label Day view
  def day_view
    render Components::Timeline.new(
      pointer: Time.zone.today,
      period: "day",
      sort: "time",
      path: "events"
    )
  end

  # @label Week view
  def week_view
    render Components::Timeline.new(
      pointer: Time.zone.today,
      period: "week",
      sort: "time",
      path: "events"
    )
  end

  # @label Month view
  def month_view
    render Components::Timeline.new(
      pointer: Time.zone.today,
      period: "month",
      sort: "time",
      path: "events"
    )
  end

  # @label Upcoming with tabs
  def upcoming
    render Components::Timeline.new(
      pointer: Time.zone.today,
      period: "upcoming",
      sort: "time",
      path: "events",
      show_upcoming: true
    )
  end
end
