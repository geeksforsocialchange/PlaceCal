# app/models/calendar.rb
class Calendar < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :partner
  belongs_to :place, required: false
  has_many :events

  validates_presence_of :name

  extend Enumerize

  # What kind of Calendar feed is this?
  enumerize :type, in: %i[facebook google outlook mac_calendar other],
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
  def import_events
    parse_event_source.group_by(&:uid).each do |uid, imports|
      if imports.first.rrule.present?
        Event.handle_recurring_events(uid, imports, id)
        next
      end

      attributes = imports.first.attributes

      if events.exists?(uid: uid)
        event = Event.find_by_uid(uid)
        event.update_attributes!(attributes.except(:uid))
      else
        event = events.new(attributes)
        event.save!
      end
    end
  end

  private

  # Import events from given URL
  def parse_event_source
    case type
    when :facebook
      Parsers::Facebook.new(source, last_import_at).events
    else
      Parsers::Ics.new(source).events
    end
  end
end
