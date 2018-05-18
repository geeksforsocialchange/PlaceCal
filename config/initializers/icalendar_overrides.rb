# frozen_string_literal: true

Icalendar::Recurrence::Schedule.class_eval do
  def timezone
    return Time.zone.name if event.tzid.blank?

    ActiveSupport::TimeZone[event.tzid].present? ? event.tzid : Time.zone.name
  end
end
