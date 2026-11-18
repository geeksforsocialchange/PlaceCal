# frozen_string_literal: true

# How a long-running event's dates read in place of its time range, shared by event cards, rows and pages.
module Components::Shared::LongRunningDates
  private

  def long_running?(event) = ::Event.long_running?(event.dtstart, event.dtend)

  # "From 28 Nov until 17 Jan 2027" in 2026
  def until_text(event)
    t('events.long_running.from_until', from: long_running_date(event.dtstart.to_date), to: long_running_date(::Event.last_day(event.dtend)))
  end

  # "28 Nov to 17 Jan 2027" in 2026
  def date_range_text(event)
    t('events.long_running.range', from: long_running_date(event.dtstart.to_date), to: long_running_date(::Event.last_day(event.dtend)))
  end

  # A date's year shows only when it isn't this year
  def long_running_date(date)
    I18n.l(date, format: date.year == Time.zone.today.year ? :long_running_no_year : :long_running)
  end
end
