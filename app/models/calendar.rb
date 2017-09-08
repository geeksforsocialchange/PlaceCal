class Calendar < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :partner
  belongs_to :place, required: false
  has_many :events

  validates_presence_of :name

  extend Enumerize

  # What kind of calendar is this?
  enumerize :type, in: [:facebook, :google, :outlook, :mac_calendar, :other], default: :other, scope: true
  # What strategy should we take to create Events?
  # Event:        use event location field from import
  # Place:        use the Calendars's associated Place
  # Room Number:  presume location field contains a room number
  enumerize :strategy, in: [:event, :place, :room_number], default: :place, scope: true

  def to_s
    name
  end

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
