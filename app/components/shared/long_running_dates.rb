# frozen_string_literal: true

# How a long-running event's dates read in place of its time range, shared by event cards, rows and pages.
module Components::Shared::LongRunningDates
  private

  def long_running?(event) = ::Event.long_running?(event.dtstart, event.dtend)

  # "From 28 Nov until 17 Jan 2027", or "From 24 until 28 Nov" in 2026
  def until_text(event)
    from, to = long_running_ends(event)
    t('events.long_running.from_until', from:, to:)
  end

  # "28 Nov to 17 Jan 2027", or "24 to 28 Nov" in 2026
  def date_range_text(event)
    from, to = long_running_ends(event)
    t('events.long_running.range', from:, to:)
  end

  def long_running_ends(event) = ::Event.long_running_dates(event.dtstart, event.dtend)
end
