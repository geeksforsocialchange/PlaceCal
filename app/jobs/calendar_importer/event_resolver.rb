# frozen_string_literal: true

# Coordinates event import: resolves location, detects online links, and saves occurrences.
#
# Delegates location resolution to LocationResolver and online detection to OnlineDetector.
class CalendarImporter::EventResolver
  attr_reader :data, :uid, :notices, :calendar

  def initialize(event_data, calendar, notices, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
    @from_date = from_date
  end

  def is_private?
    data.private?
  end

  def has_no_occurences?
    occurences.none?
  end

  def occurences
    @occurences ||= data.occurrences_between(@from_date, Calendar.import_up_to)
  end

  def determine_online_location
    CalendarImporter::OnlineDetector.new(data).detect
  end

  def determine_location_for_strategy
    place, address = CalendarImporter::LocationResolver.new(calendar, data).resolve

    data.place_id = place.id if place
    data.address_id = address&.id
    data.organiser_id = calendar.organiser_id
  end

  def save_all_occurences
    calendar_events = calendar.events.where(uid: data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if data.recurring_event?
      time_pairs = occurences.map { |o| [o.start_time, o.end_time] }
      events_with_invalid_dates = calendar_events.without_matching_times(time_pairs)
      events_with_invalid_dates.destroy_all

      # Re-query after destroy to avoid stale relation returning destroyed records
      calendar_events = calendar.events.where(uid: data.uid)
    end

    occurences.each do |occurence|
      event_time = { dtstart: occurence.start_time, dtend: occurence.end_time }
      event = nil

      if calendar_events.present?
        event = if data.recurring_event?
                  calendar_events.find_by(event_time)
                else
                  calendar_events.first
                end
      end

      # Clean up any remaining duplicates for this specific occurrence
      if event&.persisted?
        calendar_events.where(event_time).where.not(id: event.id).delete_all
      end

      event ||= calendar.events.new

      event_time[:are_spaces_available] = occurence.status if occurence.respond_to?(:status)

      attributes = data.attributes.merge(event_time)
      begin
        unless event.update(attributes)
          notices << event.errors.full_messages.join(', ')
        end
      rescue ActiveRecord::RecordNotUnique
        # Duplicate detected by DB constraint — find and update existing instead
        existing = calendar.events.find_by!(uid: data.uid, dtstart: event_time[:dtstart], dtend: event_time[:dtend])
        unless existing.update(attributes)
          notices << existing.errors.full_messages.join(', ')
        end
      end
    end
  end
end
