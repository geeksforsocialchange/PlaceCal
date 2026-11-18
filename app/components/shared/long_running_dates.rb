# frozen_string_literal: true

# How a long-running event's dates read in place of its time range, shared by event cards, rows and pages.
module Components::Shared::LongRunningDates
  private

  def long_running?(event) = ::Event.long_running?(event.dtstart, event.dtend)

  # "Until 17 Jan 2027"
  def until_text(event)
    t('events.long_running.until', date: I18n.l(::Event.last_day(event.dtend), format: :long_running))
  end

  # "28 Nov 2026 to 17 Jan 2027"
  def date_range_text(event)
    t('events.long_running.range', from: I18n.l(event.dtstart.to_date, format: :long_running),
                                   to: I18n.l(::Event.last_day(event.dtend), format: :long_running))
  end
end
