# frozen_string_literal: true

# Some feeds carry a blank or invalid TZID (e.g. the Mossley Community Centre
# calendar sets a custom 'tzid' property instead of a valid one), which makes
# icalendar-recurrence raise TZInfo::InvalidTimezoneIdentifier or expand
# occurrences in the wrong zone. Fall back to PanCal's default time zone.
# This lived in a PlaceCal initializer before the gem extraction; it must
# ship with the gem so standalone use matches in-Rails behaviour.
Icalendar::Recurrence::Schedule.class_eval do
  def timezone
    return PanCal.default_time_zone if event.tzid.blank? ||
                                       (event.parent.custom_properties['tzid']&.first == PanCal.default_time_zone)

    ActiveSupport::TimeZone[event.tzid].present? ? event.tzid : PanCal.default_time_zone
  end
end
