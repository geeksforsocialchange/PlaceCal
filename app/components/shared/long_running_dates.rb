# frozen_string_literal: true

# How a long-running event's dates read in place of its time range, shared by event cards, rows and pages.
module Components::Shared::LongRunningDates
  private

  def long_running?(event) = ::Event.long_running?(event.dtstart, event.dtend)

  # "From 28 Nov until 17 Jan 2027", with the start's year only when it differs from the end's
  def until_text(event)
    start = event.dtstart.to_date
    last = ::Event.last_day(event.dtend)
    t('events.long_running.from_until', from: I18n.l(start, format: start.year == last.year ? :long_running_no_year : :long_running),
                                        to: I18n.l(last, format: :long_running))
  end

  # "28 Nov 2026 to 17 Jan 2027"
  def date_range_text(event)
    t('events.long_running.range', from: I18n.l(event.dtstart.to_date, format: :long_running),
                                   to: I18n.l(::Event.last_day(event.dtend), format: :long_running))
  end
end
