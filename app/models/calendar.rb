class Calendar < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :partner
  belongs_to :place, required: false
  has_many :events

  validates_presence_of :name

  extend Enumerize

  # What kind of Calendar feed is this?
  enumerize :type, in: [:facebook, :google, :outlook, :mac_calendar, :other], default: :other, scope: true
  
  # What strategy should we take to divine Event locations?
  #---------------------------------------------------------------------------------------------------------------------
  # Event:          Use the Event's location field from the imported record
  #                   => Area calendars, or organisations with no solid base.
  # Place:          Use the Calendars's associated Place and ignore the Event information
  #                   => Every event is in a single location, and we want to ignore the event location entirely
  # Room Number:    Use the Calendars's associated Place & presume the location field contains a room number
  #                   => Every event is in a large venue and the location field is being used to store the room number
  # EventOverride:  Use the Calendar's associated Place, unless an address is present.
  #                   => Everything is in one place, but there are occasional away days or one-off events
  #---------------------------------------------------------------------------------------------------------------------
  enumerize :strategy, in: [:event, :place, :room_number, :event_override], default: :place, scope: true

  def to_s
    name
  end

  # Create Events using this Calendar
  def import_events
    event_imports = type.facebook? ? Parsers::Facebook.new(source, last_import_at).events : Parsers::Ics.new(source).events

    event_imports.group_by(&:uid).each do |uid, imports|
      if imports.first.rrule.present?
        Event.handle_recurring_events(uid, imports, self.id)
        next
      end

      attributes = imports.first.attributes

      if events.exists?(uid: uid)
        event = Event.find_by_uid(uid)
        event.update_attributes!(attributes.except(:uid))
      else
        event = self.events.new(attributes)
        event.save!
      end
    end
  end

end
