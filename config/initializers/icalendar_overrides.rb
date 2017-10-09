Icalendar::Recurrence::Schedule.class_eval do
  def timezone
    ActiveSupport::TimeZone[event.tzid].present? ? event.tzid : Time.zone.name
  end
end

