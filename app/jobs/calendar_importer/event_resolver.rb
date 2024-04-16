# frozen_string_literal: true

class CalendarImporter::EventResolver
  WARNING1_MSG = 'Could not determine where this event is. Add an address to the location field of the source ' \
                 'calendar, or choose another import strategy with a default location'
  WARNING2_MSG = 'Could not determine where this event is. A default location is set but the importer is set '  \
                 'to ignore this. Add an address to the location field of the source calendar, or choose '      \
                 'another import strategy with a default location.'

  attr_reader :data, :uid, :notices, :calendar

  class Problem < StandardError; end

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
    occurences.count.zero?
  end

  def is_address_missing?
    data.address_id.nil?
  end

  def occurences
    @occurences ||= data.occurrences_between(@from_date, Calendar.import_up_to)
  end

  def determine_online_location
    data.online_address_id = data.online_event?
  end

  def determine_location_for_strategy
    # this algorithm is derived from the notion doc at
    #   GFSC
    #     PlaceCal
    #       PlaceCal Handbook
    #         PlaceCal developer handbook
    #           How does the Calendar importer detect Places and Addresses?

    strategies = {
      'event' => :event_strategy,
      'event_override' => :event_override_strategy,
      'place' => :place_strategy,
      'room_number' => :room_number_strategy,
      'no_location' => :no_location_strategy,
      'online_only' => :online_only_strategy
    }

    if strategies.key?(calendar.strategy)
      strategy = strategies[calendar.strategy]
      partner, address = method(strategy).call(calendar.place)
    else
      # this shouldn't happen and should be fatal to the entire job
      raise "Calendar import strategy unknown! (ID=#{calendar.id}, strategy=#{calendar.strategy})"
    end

    # NOTE: In this context, data is a calendar object. But this doesn't make sense because
    #       determine_online_location sees a CalendarImporter::Events::IcsEvent object?
    data.place_id = partner.id if partner
    data.address_id = address&.id
    data.partner_id = calendar.partner_id
  end

  def event_strategy(partner, address: nil)
    if data.has_location?
      address = Address.build_from_components(event_location_components, data.postcode)
      partner = nil
    elsif partner.present?
      raise Problem, WARNING2_MSG
    end
    [partner, address]
  end

  def event_override_strategy(partner, address: nil)
    if data.has_location?
      address = Address.build_from_components(event_location_components, data.postcode)
      partner = nil
    elsif partner.present?
      address = partner.address
    else
      raise Problem, WARNING1_MSG
    end
    [partner, address]
  end

  def place_strategy(_partner, _address: nil)
    [calendar.place, calendar.place.address]
    # NOTE: calendar.place can be nil, in which case this event will be dropped on the floor
    #       (Likely what is happening with Velociposse?)
  end

  def room_number_strategy(partner, address: nil)
    if data.has_location?
      if partner.present?
        new_address = partner.address.dup
        address = new_address.prepend_room_number(data.location)
        address.save
      else # no partner, yes location
        raise Problem, 'N/A'
      end
    elsif partner.present? # no location
      address = partner.address
    else # no place, no location
      raise Problem, 'N/A'
    end
    [partner, address]
  end

  def no_location_strategy(_partner, _address: nil)
    [nil, nil]
  end

  def online_only_strategy(_partner, _address: nil)
    [nil, nil]
  end

  def save_all_occurences
    calendar_events = calendar.events.where(uid: data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurences.map(&:start_time),
                                                                         occurences.map(&:end_time))
      events_with_invalid_dates.destroy_all
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

      event ||= calendar.events.new

      event_time[:are_spaces_available] = occurence.status if occurence.respond_to?(:status)

      attributes = data.attributes.merge(event_time)
      unless event.update(attributes)
        notices << event.errors.full_messages.join(', ')
      end

      if event.address_id.blank? && calendar.strategy == 'event'
        notices << "No place or address could be created or found for the event location: #{event.raw_location_from_source}"
      end
    end
  end

  def event_location_components
    return @event_location_components if @event_location_components

    regex_string = 'UK|United Kingdom'
    regex_string += "|#{data.postcode.strip}" if data.postcode.present?

    regexp = Regexp.new(regex_string, Regexp::IGNORECASE)

    @event_location_components = (data.location || '')
                                 .split(', ')
                                 .map { |component| component.gsub(regexp, '').strip }
                                 .compact_blank
  end
end
