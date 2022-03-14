module Types
  class EventType < Types::BaseObject

    field :id, ID, null: false
    field :name, String, method: :summary
    field :summary, String
    field :description, String
    field :startDate, String, method: :dtstart, null: false
    field :endDate, String, method: :dtend

    field :address, AddressType
    field :organizer, PartnerType, method: :partner

  end
end

