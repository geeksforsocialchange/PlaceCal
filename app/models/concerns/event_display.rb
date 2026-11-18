# frozen_string_literal: true

# How an event's times, dates and repeats read on pages, feeds and share cards
module EventDisplay
  extend ActiveSupport::Concern

  class_methods do
    # icalendar < 2.13 serialised each rule as an OpenStruct (keys under "table"), 2.13+ as a flat Struct.
    # @return [String, nil] raw RFC 5545 FREQ value, e.g. "WEEKLY"
    def rrule_frequency(rrule)
      rule = rrule.is_a?(Array) ? rrule.first : nil
      return if rule.blank?

      (rule['table'] || rule)['frequency'].presence
    end
  end

  # @return [String, nil] human-readable recurrence label (e.g. "Weekly")
  def repeat_frequency
    self.class.rrule_frequency(rrule)&.titleize
  end

  # Whether the event's webpage is on a ticketing platform, going by the importer its calendar last used
  def ticketed?
    parser = CalendarImporter::CalendarImporter.parser_for_key(calendar&.importer_used)
    parser.present? && parser::TICKETING
  end

  # Feeds without an end time give one equal to the start
  def ends? = dtend.present? && dtend != dtstart

  # @return [String] formatted time range, e.g. "09:00 – 10:00"
  def time
    if ends?
      "#{dtstart.strftime('%H:%M')} – #{dtend.strftime('%H:%M')}"
    else
      dtstart.strftime('%H:%M')
    end
  end

  # @return [String] short date, e.g. "1 Jan"
  def date
    dtstart.strftime('%-d %b')
  end

  # @return [String] date with year, e.g. "1 Jan 2026"
  def date_year
    dtstart.strftime('%-d %b %Y')
  end

  # @return [String] Open Graph title combining summary, date, time, and organiser
  def og_title
    str = if long_running?
            "#{summary}, #{I18n.t('events.long_running.range', from: date, to: self.class.last_day(dtend).strftime('%-d %b'))}"
          elsif all_day?
            "#{summary}, #{date}"
          else
            "#{summary}, #{date}, #{time}"
          end
    str += " @ #{organiser.name}" if organiser
    str
  end

  # Starts at midnight and ends at midnight, or has no end: imported all-day events look like this.
  # @return [Boolean]
  def all_day?
    dtstart == dtstart.beginning_of_day && (dtend.nil? || dtend == dtend.beginning_of_day)
  end
end
