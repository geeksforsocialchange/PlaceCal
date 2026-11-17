# frozen_string_literal: true

# @display width page
class Sites::TimelinePreview < Lookbook::Preview
  # @label Day view
  def day_view
    render Components::Sites::Timeline.new(
      pointer: Time.zone.today,
      period: "day",
      sort: "time",
      path: "events"
    )
  end

  # @label Week view
  def week_view
    render Components::Sites::Timeline.new(
      pointer: Time.zone.today,
      period: "week",
      sort: "time",
      path: "events"
    )
  end

  # @label Month view
  def month_view
    render Components::Sites::Timeline.new(
      pointer: Time.zone.today,
      period: "month",
      sort: "time",
      path: "events"
    )
  end

  # @label Upcoming with tabs
  def upcoming
    render Components::Sites::Timeline.new(
      pointer: Time.zone.today,
      period: "upcoming",
      sort: "time",
      path: "events",
      show_upcoming: true
    )
  end

  # A week view that runs across a month end, where tab labels name both months.
  # @label Week view across a month end
  def week_view_across_months
    render Components::Sites::Timeline.new(
      pointer: Date.new(2026, 12, 22),
      period: "week",
      sort: "time",
      path: "events"
    )
  end

  # The week view at a phone's width, where the paginator hides tabs that don't fit.
  # @label Week view on a phone
  def week_view_phone
    render Narrow.new(Components::Sites::Timeline.new(pointer: Date.new(2026, 12, 22), period: "week", sort: "time", path: "events"))
  end

  class Narrow < Phlex::HTML
    def initialize(component)
      super()
      @component = component
    end

    def view_template
      div(style: "max-width: 390px") { render @component }
    end
  end
end
