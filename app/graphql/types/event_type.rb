# frozen_string_literal: true

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
          description: 'The organising partner of this event'

    field :publisherUrl, String,
          method: :publisher_url,
          description: 'The URL of the partners original page'

    field :onlineEventUrl, String,
          description: 'The URL of the online event. Can be an event link e.g. Eventbrite, or a Zoom/Meet/Jitsi link'

    field :onlineEventUrlType, String,
          description: 'Whether the URL of the online event is a link to the live stream (direct)'\
                       ' or to an intermediary (indirect).'

    def onlineEventUrl
      object&.online_address&.url
    end

    def onlineEventUrlType
      object&.online_address&.link_type
    end

    def organizer
      partner = object&.partner
      return if partner.blank? || partner.hidden

      partner
    end
  end
end
