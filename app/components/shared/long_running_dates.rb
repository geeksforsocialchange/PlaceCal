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

  # The end shows its year unless it's this year; the start drops what it shares with the end
  def long_running_ends(event)
    first = event.dtstart.to_date
    last = ::Event.last_day(event.dtend)
    format = if first.year == last.year && first.month == last.month then :long_running_day
             elsif first.year != last.year && first.year != Time.zone.today.year then :long_running
             else :long_running_no_year
             end
    [I18n.l(first, format:), I18n.l(last, format: last.year == Time.zone.today.year ? :long_running_no_year : :long_running)]
  end
end
