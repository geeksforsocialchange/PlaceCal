module Types
  class EventType < Types::BaseObject
    description 'An event represents a date in time that a partner operates their service, meetup, workout or class etc'

    field :id, ID, 
      null: false,
      description: 'Our internal ID for further querying'

    # Summary and name are aliases, this is left as a convenience 
    #   for people used to iCal format
    field :name, String, 
      method: :summary,
      description: 'An alias for `summary`'

    field :summary, String,
      description: 'The title of the event'

    field :description, String,
      description: 'A longer text about this event covering more detail'

    field :startDate, GraphQL::Types::ISO8601DateTime, 
      method: :dtstart, 
      null: false,
      description: 'The date (and time) when this event begins'

    field :endDate, GraphQL::Types::ISO8601DateTime, 
      method: :dtend,
      description: 'The end date of this event if the event goes on for more than one day (i.e. a conference weekend)'

    field :address, AddressType,
      description: 'The address where this event will take place'

    field :organizer, PartnerType, 
      method: :partner,
      description: 'The organising partner of this event'

  end
end

