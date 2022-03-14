module Types
  class EventType < Types::BaseObject

    field :id, ID, null: false
    # Summary and name are aliases, this is left as a convenience 
    #   for people used to iCal format
    field :name, String, method: :summary
    field :summary, String
    field :description, String
    field :startDate, String, method: :dtstart, null: false
    field :endDate, String, method: :dtend

    field :address, AddressType
    field :organizer, PartnerType, method: :partner

  end
end

