# frozen_string_literal: true

Icalendar::Recurrence::Schedule.class_eval do
  def timezone
    #Timezone is missing or incorrectly set.
    #Check to see if custom properties contains invalid tzid property (ex. Mossley Community Center calendar)
    #and verify it matches default timezone (Europe/London)
    return Time.zone.name if event.tzid.blank? || (event.parent.custom_properties['tzid']&.first == Time.zone.name)

    ActiveSupport::TimeZone[event.tzid].present? ? event.tzid : Time.zone.name
  end
end
