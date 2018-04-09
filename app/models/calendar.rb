# app/models/calendar.rb
class Calendar < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :partner
  belongs_to :place, required: false
  has_many :events, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :source

  IMPORT_UP_TO = 1.year.from_now

  extend Enumerize

  # What kind of Calendar feed is this?
  enumerize :type, in: %i[facebook google outlook mac_calendar xml other],
                   default: :other,
                   scope: true

  # What strategy should we take to divine Event locations?
  #----------------------------------------------------------------------------
  # Event: Use the Event's location field from the imported record
  #   => Area calendars, or organisations with no solid base.
  # Place: Use the Calendars's associated Place and ignore the Event information
  #   => Every event is in a single location, and we want to ignore the
  #      event location entirely
  # Room Number: Use the Calendars's associated Place & presume the location
  #      field contains a room number
  #   => Every event is in a large venue and the location field is being used to
  #      store the room number
  # EventOverride: Use Calendar's associated Place, unless address is present.
  #   => Everything is in one Place, with occasional away days or one-off events
  #-----------------------------------------------------------------------------
  enumerize :strategy, in: %i[event place room_number event_override],
                       default: :place,
                       scope: true

  # Default output
  def to_s
    name
  end

  # Create Events using this Calendar
  def import_events(from)
    update_attribute(:import_lock_at, DateTime.now)

    @notices = []
    @events_uids = []

    parse_events_from_source(from).each do |event_data|
      occurrences = event_data.occurrences_between(from, Calendar::IMPORT_UP_TO)
      next if event_data.private? || occurrences.blank?

      @events_uids << event_data.uid
      event_data.partner_id = partner_id

      if ['place', 'room_number'].include?(strategy)
        event_data.place_id = place_id
      else
        location = set_place_or_address(event_data)
        event_data.send("#{location.keys[0]}=", location.values[0]) if location.try(:keys).present?
      end

      @notices += create_or_update_events(event_data, occurrences, from)
    end

    handle_deleted_events(from, @events_uids) if @events_uids

    self.reload #reload the record from database to clear out any invalid events to avoid attempts to save them
    self.update_attributes!({last_import_at: DateTime.now, import_lock_at: nil, notices: @notices })
  end

  def create_or_update_events(event_data, occurrences, from) # rubocop:disable all
    @important_notices = []
    calendar_events    = self.events.upcoming_for_date(from).where(uid: event_data.uid)

    #If any dates of this event don't match the imported start times or end times, delete them
    if event_data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurrences.map(&:start_time), occurrences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurrences.each do |occurrence|
      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time, are_spaces_available: occurrences.status }

      event = event_data.recurring_event? ? calendar_events.find_by(event_time) : calendar_events.first if calendar_events.present?
      event = self.events.new if event.blank?

      unless event.update_attributes event_data.attributes.merge(event_time)
        @important_notices << { event: event, errors: event.errors.full_messages }
      end

    end

    @important_notices
  end

  def handle_deleted_events(from, uids)
    upcoming_events = self.events.upcoming_for_date(from)
    deleted_events = upcoming_events.where.not(uid: uids).pluck(:uid)

    return if deleted_events.blank?

    if type.facebook?
      #Do another check with Facebook to see if these events actually no
      #longer exist in case of FB hiccup. If they do exist, remove from the list.
      response = Parsers::Facebook.new(source).find_by_uid(deleted_events)
      response.keys.each { |key| deleted_events.delete(key) }
    end

    upcoming_events.where(uid: deleted_events).destroy_all
  end

  private

  # Import events from given URL
  def parse_events_from_source(from)
    case type
    when "facebook"
      Parsers::Facebook.new(source, { from: from }).events
    else
      Parsers::Ics.new(source).events
    end
  end

  def set_place_or_address(event_data)
    location = event_data.location

    return (strategy.event_override? ? { place_id: place_id } : {}) if location.blank?

    postcode   = event_data.postcode
    regexp     = postcode.present? ? Regexp.new("#{postcode.strip}|UK|United Kingdom") : Regexp.new("UK|United Kingdom")
    components = location.split(', ').map { |component| component.gsub(regexp, '').strip }.reject(&:blank?)

    if place = Place.where(name: components).first
      return { place_id: place.id }
    else
      return Address.search(location, components, postcode)
    end
  end

end
